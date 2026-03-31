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
    doomLocalDir = "${config.xdg.dataHome}/doom";
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
    };
  };
  services.emacs = {
    enable = true;
    startWithUserSession = "graphical";
  };
}
