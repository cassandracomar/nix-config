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
  scratchDoom = pkgs.doomEmacs {
    inherit emacs extraPackages emacsPackageOverrides doomLocalDir;
    doomDir = inputs.doom-config;
    experimentalFetchTree = true;
  };

  doomCompileScript = pkgs.writeText "compile-doomdir.el" ''
    ;;; -*- lexical-binding: t; -*-
    (add-to-list 'load-path default-directory)
    (add-to-list 'load-path (expand-file-name "agent" default-directory))

    (doom-modules-initialize)
    (load (doom-profile-init-file doom-profile) nil 'nomessage 'must-suffix)
    (catch 'exit (doom-startup))

    (setq byte-compile-warnings nil
          load-prefer-newer t
          native-comp-async-report-warnings-errors nil)

    (let ((target (getenv "EMACSNATIVELOADPATH")))
      (when (and target (not (string-empty-p target)))
        (setq native-comp-eln-load-path
              (cons target (delete target native-comp-eln-load-path)))))

    (let* ((args command-line-args-left)
           (_ (when (string= (car args) "--") (pop args)))
           (mode (pop args)))
      (setq command-line-args-left nil)
      (dolist (f args)
        (catch 'exit
          (condition-case err
              (pcase mode
                ("byte" (byte-compile-file f))
                ("native" (native-compile f)))
            (error (princ (format "%s failed for %s: %S\n" mode f err)))))))
  '';

  compiledDoomDir =
    pkgs.runCommandLocal "doom-config-compiled" {
      nativeBuildInputs = with pkgs; [scratchDoom git man];
      EMACS = "${scratchDoom.emacsWithPackages}/bin/emacs";
      DOOMPROFILELOADFILE = "${scratchDoom.doomProfile}/loader/init";
      DOOMPROFILE = "nix";
      DOOMDIR = "${scratchDoom.doomProfile}/doomdir";
    } ''
      mkdir -p $out $out/eln-cache
      cp -rL ${inputs.doom-config}/. $out/
      chmod -R u+w $out

      export HOME=$PWD/doom-home
      export DOOMLOCALDIR=$PWD/doom-local
      mkdir -p $HOME $DOOMLOCALDIR

      cd $out
      files=$(find . -name '*.el' \
                ! -name init.el ! -name packages.el -type f -printf '%P\n')

      doomscript=${scratchDoom.doomSource}/bin/doomscript

      # Pass 1: byte-compile our private config via doomscript so all doom
      # macros expand. Only our config lives under the writable $out, so this
      # pass is scoped to it ($out is the doomscript's cwd / DOOMDIR).
      ${pkgs.runtimeShell} $doomscript ${doomCompileScript} byte $files

      # Pass 2: native-compile our config
      EMACSNATIVELOADPATH="$out/eln-cache/" \
        ${pkgs.runtimeShell} $doomscript ${doomCompileScript} native \
          $files $coreFiles $moduleFiles
    '';

  doomDepsNativeLisp = "${config.programs.doom-emacs.finalDoomPackage.emacsWithPackages.deps}/share/emacs/native-lisp";
  finalEmacsWithEln =
    pkgs.runCommandLocal "emacs-with-doom-eln" {
      nativeBuildInputs = [pkgs.makeBinaryWrapper];
      inherit (config.programs.doom-emacs.finalEmacsPackage) meta;
    } ''
      mkdir -p $out/bin
      for name in emacs emacsclient ebrowse etags; do
        src=${config.programs.doom-emacs.finalEmacsPackage}/bin/$name
        case "$name" in
          emacs|emacsclient)
            makeWrapper "$src" "$out/bin/$name" \
              --suffix EMACSNATIVELOADPATH : "${compiledDoomDir}/eln-cache" \
              --suffix EMACSNATIVELOADPATH : "${doomDepsNativeLisp}"
            ;;
          *)
            cp -P "$src" "$out/bin/$name"
            ;;
        esac
      done
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
    emacs-lsp-booster
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
      emacs-lsp-booster
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
