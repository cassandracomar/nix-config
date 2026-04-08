{
  pkgs,
  inputs,
  config,
  ...
}: {
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
    config.programs.doom-emacs.finalDoomPackage
    emacs-lsp-booster
    mu
    python3Packages.grip
    helm-ls
    jsonnet-language-server
    bash-language-server
    vscode-json-languageserver
  ];

  systemd.user.startServices = true;

  programs.doom-emacs = {
    enable = true;
    doomDir = inputs.doom-config;
    doomLocalDir = "${config.xdg.dataHome}/nix-doom";
    experimentalFetchTree = true;
    extraPackages = epkgs:
      with epkgs; [
        vterm
        sqlite3
        emacsql
        treesit-grammars.with-all-grammars
        mu4e
      ];
    extraBinPackages = with pkgs; [
      nixd
      gnumake
      sqlite
      pinentry-emacs
      emacs-lsp-booster
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
  };
  services.emacs = {
    enable = true;
    startWithUserSession = "graphical";
  };
}
