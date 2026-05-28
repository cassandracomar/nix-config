{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  emacs = config.programs.doom-emacs.emacs;

  extraPackages = epkgs:
    with epkgs; [
      vterm
      sqlite3
      emacsql
      treesit-grammars.with-all-grammars
    ];

  emacsPackageOverrides = final: prev: {
    dumb-jump = prev.dumb-jump.overrideAttrs (old: {
      packageRequires = (old.packageRequires or []) ++ [final.dash];
    });
    claude-code-ide-extras-emacs = prev.claude-code-ide-extras-emacs.overrideAttrs (old: {
      packageRequires = (old.packageRequires or []) ++ [final.claude-code-ide final.projectile];
    });
    agent-shell-ediff = prev.agent-shell-ediff.overrideAttrs (old: {
      packageRequires = (old.packageRequires or []) ++ [final.agent-shell];
    });
    agent-shell-dispatch = prev.agent-shell-dispatch.overrideAttrs (old: {
      packageRequires = (old.packageRequires or []) ++ [final.agent-shell];
    });
  };

  doomLocalDir = "${config.xdg.dataHome}/nix-doom";

  # Scratch doom build whose only purpose is to expose emacsWithPackages so
  # we can byte-compile the user config against the same package set the live
  # runtime uses. Nix dedupes the heavy work (package fetches + builds) with
  # the final doomEmacs derivation; the only marginal cost is one extra
  # doom-profile derivation (which just symlinks and runs two doomscripts).
  scratchDoom = pkgs.doomEmacs {
    inherit emacs extraPackages emacsPackageOverrides doomLocalDir;
    doomDir = inputs.doom-config;
    experimentalFetchTree = true;
  };

  # Wrap the doomdir in a derivation that byte- AND native-compiles every
  # helper file. init.el and packages.el are owned by doom's profile build,
  # so we skip those. Byte-compile is per-file so a single failure (e.g.
  # missing autoload-only dep) doesn't abort the whole build; the
  # native-compile pass walks `comp-files-queue' to completion and writes
  # .eln files under $out/eln-cache, which the wrapper below feeds to the
  # runtime via EMACSNATIVELOADPATH so config.el itself is loaded natively.
  compiledDoomDir = pkgs.runCommandLocal "doom-config-compiled" {
    nativeBuildInputs = [scratchDoom.emacsWithPackages];
  } ''
    mkdir -p $out $out/eln-cache
    cp -rL ${inputs.doom-config}/. $out/
    chmod -R u+w $out

    cd $out
    files=$(find . -maxdepth 2 -name '*.el' \
              ! -name init.el ! -name packages.el -type f -printf '%P\n')

    # Doom helpers like `+calfw-khal.el' `(require 'doom-lib)' etc., so
    # doom's own lisp dir has to be on the load-path during compile.
    doom_lisp=${scratchDoom.doomSource}/lisp

    # Pass 1: byte-compile (writes .elc next to .el). Per-file so any single
    # failure surfaces individually but doesn't hide later ones.
    for f in $files; do
      emacs --batch \
        -L $out -L $out/agent -L $doom_lisp \
        --eval '(setq byte-compile-warnings nil)' \
        --eval '(setq load-prefer-newer t)' \
        -f batch-byte-compile "$f" || echo "byte-compile skipped: $f"
    done

    # Pass 2: native-compile. EMACSNATIVELOADPATH puts $out/eln-cache first
    # in `native-comp-eln-load-path' so the .eln output lands there;
    # subprocesses inherit the env var, which `native-compile-target-directory'
    # alone does not propagate. .eln files land in
    # $out/eln-cache/<comp-native-version-dir>/. batch-native-compile is left
    # in fail-fast mode so we surface and fix errors instead of silently
    # skipping files that should be compilable.
    EMACSNATIVELOADPATH="$out/eln-cache/" emacs --batch \
      -L $out -L $out/agent -L $doom_lisp \
      --eval '(setq native-comp-async-report-warnings-errors nil)' \
      -f batch-native-compile $files
  '';

  # Stack a second C wrapper on top of doom's emacs-with-doom wrapper that
  # adds EMACSNATIVELOADPATH pointing at compiledDoomDir/eln-cache. The
  # underlying wrapper sets DOOM* env vars and is preserved by --inherit-argv0
  # of the inner makeBinaryWrapper; ours layers EMACSNATIVELOADPATH on top so
  # the runtime resolves .eln files for the user's helpers (including
  # config.el) without putting an `add-to-list' in config.el itself (which
  # would defeat the purpose -- config.el wouldn't be loaded natively because
  # the eln load path wouldn't be set yet).
  finalEmacsWithEln = pkgs.runCommandLocal "emacs-with-doom-eln" {
    nativeBuildInputs = [pkgs.makeBinaryWrapper];
    inherit (config.programs.doom-emacs.finalEmacsPackage) meta;
  } ''
    mkdir -p $out/bin
    for f in ${config.programs.doom-emacs.finalEmacsPackage}/bin/*; do
      name=$(basename "$f")
      makeWrapper "$f" "$out/bin/$name" \
        --suffix EMACSNATIVELOADPATH : "${compiledDoomDir}/eln-cache"
    done
    # Mirror non-bin output paths (share, lib, ...) so resource lookups
    # (info files, locale data, etc.) still resolve through this derivation.
    for d in ${config.programs.doom-emacs.finalEmacsPackage}/*; do
      name=$(basename "$d")
      [ "$name" = bin ] && continue
      ln -s "$d" "$out/$name"
    done
  '';
in {
  home.packages = with pkgs; [
    sqlite
    direnv
    p7zip
    unrar
    unzip
    nixfmt
    alejandra
    nixd
    ripgrep
    pandoc
    yaml-language-server
    yaml-schema-router
    dockerfile-language-server
    # gcc
    # stdenv_mold
    gnumake
    # `emacs' binary (wrapped to add EMACSNATIVELOADPATH so config.el itself
    # is loaded from .eln). `doom-emacs' binary is auto-installed by the HM
    # module when provideEmacs=false.
    finalEmacsWithEln
    (emacs-lsp-booster.override {inherit emacs;})
    python3Packages.grip
    helm-ls
    jsonnet-language-server
    bash-language-server
    vscode-json-languageserver
  ];

  systemd.user.startServices = true;

  programs.doom-emacs = {
    enable = true;
    doomDir = compiledDoomDir;
    inherit doomLocalDir extraPackages emacsPackageOverrides;
    experimentalFetchTree = true;
    # Have HM auto-install only the `doom-emacs' binary; we install our
    # eln-wrapped `emacs' binary manually via home.packages above.
    provideEmacs = false;
    extraBinPackages = with pkgs; [
      nixd
      gnumake
      sqlite
      pinentry-emacs
      (emacs-lsp-booster.override {inherit emacs;})
    ];
  };
  services.emacs = {
    enable = true;
    startWithUserSession = "graphical";
    # HM only wires services.emacs.package to finalEmacsPackage when
    # provideEmacs=true; since we turned that off, set the daemon's emacs to
    # the eln-wrapped binary explicitly so emacsclient sessions also pick up
    # the precompiled .eln cache.
    package = finalEmacsWithEln;
  };
}
