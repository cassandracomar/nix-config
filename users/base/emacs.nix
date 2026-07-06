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
    eat = prev.eat.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.ncurses];
      postBuild = ''
        make terminfo
      '';
      postInstall = ''
        mkdir -p $out/share
        cp -r terminfo $out/share
      '';
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
    (when (hash-table-p doom-modules)
      (maphash (lambda (key module)
                 (put (car key) (cdr key) (doom-module->context module)))
               doom-modules))
    (catch 'exit (doom-startup))

    (setq byte-compile-warnings nil
          load-prefer-newer t
          native-comp-async-report-warnings-errors nil
          inhibit-debugger t
          debug-on-error nil
          debug-on-signal nil)

    (let ((target (getenv "EMACSNATIVELOADPATH")))
      (when (and target (not (string-empty-p target)))
        (setq native-comp-eln-load-path
              (cons target (delete target native-comp-eln-load-path)))))

    ;; Invocation: doomscript THIS MODE LISTFILE
    ;;   MODE     = "byte" | "native"
    ;;   LISTFILE = path to a newline-separated list of .el files to compile.
    ;; Reading the file list from a file (rather than argv) keeps it robust to
    ;; doomscript's own argument handling and lets the shell shard the list for
    ;; parallel invocations.
    (let* ((args command-line-args-left)
           (_ (when (string= (car args) "--") (pop args)))
           (mode (pop args))
           (listfile (pop args))
           (files (with-temp-buffer
                    (insert-file-contents listfile)
                    (split-string (buffer-string) "\n" t))))
      (setq command-line-args-left nil)
      (dolist (f files)
        (catch 'exit
          (condition-case err
              (pcase mode
                ("byte" (byte-compile-file f))
                ("native" (native-compile f)))
            ;; Catch everything (t), not just `error': skipping a file that
            ;; won't compile must never abort the build.
            (t (princ (format "%s skipped %s: %S\n" mode f err)))))))
  '';

  parallelCompile = ''
    jobs=''${NIX_BUILD_CORES:-1}
    [ "$jobs" -lt 1 ] && jobs=1

    printf '%s\n' "$files" > all-files.txt
    nfiles=$(grep -c . all-files.txt || true)
    echo "compiling $nfiles files across $jobs shards"

    # Split into $jobs round-robin shards (round-robin balances large/small files).
    rm -rf shards && mkdir shards
    awk -v j="$jobs" 'NF{print > ("shards/shard." (NR % j))}' all-files.txt

    run_pass () {
      mode=$1
      pids=""
      for shard in shards/shard.*; do
        [ -s "$shard" ] || continue
        EMACSNATIVELOADPATH="$ELN" \
          ${pkgs.runtimeShell} "$doomscript" ${doomCompileScript} "$mode" "$shard" &
        pids="$pids $!"
      done
      rc=0
      for p in $pids; do wait "$p" || rc=1; done
      return $rc
    }

    # Pass 1: byte-compile (creates .elc next to each .el -- the eln-substitution
    # trigger).
    run_pass byte
    # Pass 2: native-compile into $ELN.
    run_pass native
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
      ELN="$out/eln-cache/"
      ${parallelCompile}
    '';

  compileDoomTree = name: src:
    pkgs.runCommandLocal name {
      nativeBuildInputs = with pkgs; [scratchDoom git man];
      EMACS = "${scratchDoom.emacsWithPackages}/bin/emacs";
      DOOMPROFILELOADFILE = "${scratchDoom.doomProfile}/loader/init";
      DOOMPROFILE = "nix";
      DOOMDIR = "${scratchDoom.doomProfile}/doomdir";
      disallowedReferences =
        lib.optional (name == "doom-core-compiled")
        inputs.nix-doom.inputs.doomemacs-modules;
    } ''
      mkdir -p $out $out/eln-cache
      cp -rL ${src}/. $out/
      chmod -R u+w $out

      export HOME=$PWD/doom-home
      export DOOMLOCALDIR=$PWD/doom-local
      mkdir -p $HOME $DOOMLOCALDIR

      cd $out
      files=$(find . -name '*.el' ! -name packages.el \
                ! -path './lisp/lib/profiles.el' -type f -printf '%P\n')

      doomscript=${scratchDoom.doomSource}/bin/doomscript
      ELN="$out/eln-cache/"
      ${parallelCompile}
    '';

  compiledCore = compileDoomTree "doom-core-compiled" inputs.nix-doom.inputs.doomemacs;
  compiledModules = compileDoomTree "doom-modules-compiled" inputs.nix-doom.inputs.doomemacs-modules;

  realDoom = pkgs.callPackage (inputs.nix-doom + "/default.nix") {
    inherit emacs extraPackages emacsPackageOverrides doomLocalDir;
    doomDir = compiledDoomDir;
    doomSource = compiledCore;
    doomModules = compiledModules;
    experimentalFetchTree = true;
    toInit = lib.const (lib.const "");
  };

  doomDepsNativeLisp = "${realDoom.doomEmacs.emacsWithPackages.deps}/share/emacs/native-lisp";
  finalEmacsWithEln =
    pkgs.runCommandLocal "emacs-with-doom-eln" {
      nativeBuildInputs = [pkgs.makeBinaryWrapper];
      inherit (realDoom.emacsWithDoom) meta;
    } ''
      mkdir -p $out/bin
      for name in emacs emacsclient ebrowse etags; do
        src=${realDoom.emacsWithDoom}/bin/$name
        case "$name" in
          emacs|emacsclient)
            makeWrapper "$src" "$out/bin/$name" \
              --suffix EMACSNATIVELOADPATH : "${compiledDoomDir}/eln-cache" \
              --suffix EMACSNATIVELOADPATH : "${compiledCore}/eln-cache" \
              --suffix EMACSNATIVELOADPATH : "${compiledModules}/eln-cache" \
              --suffix EMACSNATIVELOADPATH : "${doomDepsNativeLisp}"
            ;;
          *)
            cp -P "$src" "$out/bin/$name"
            ;;
        esac
      done
      for d in ${realDoom.emacsWithDoom}/*; do
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
    finalEmacsWithEln
    emacs-lsp-booster
    python3Packages.grip
    helm-ls
    jsonnet-language-server
    bash-language-server
    vscode-json-languageserver
    codex-acp
    claude-agent-acp
  ];

  systemd.user.startServices = true;

  programs.doom-emacs = {
    enable = true;
    doomDir = compiledDoomDir;
    inherit doomLocalDir extraPackages emacsPackageOverrides;
    experimentalFetchTree = true;
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
    package = finalEmacsWithEln;
  };
}
