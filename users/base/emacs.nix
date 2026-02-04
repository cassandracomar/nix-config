{
  pkgs,
  inputs,
  config,
  ...
}: let
  yaml-language-server = pkgs.yaml-language-server.overrideAttrs (old: {
    version = "1.20.1";
    src = pkgs.fetchFromGitHub {
      owner = "redhat-developer";
      repo = "yaml-language-server";
      rev = "fefd3a6dd9758bec0ef3690b2797e5e939feadc8";
      hash = "sha256-7Qhgu/14vvCL5MK+MJ4hq1B50PtlEZEQgkG01/6sDqg=";
    };
    npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  });
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
    nodePackages.bash-language-server
    yaml-language-server
    dockerfile-language-server
    # gcc
    # stdenv_mold
    gnumake
    config.programs.doom-emacs.finalDoomPackage
    emacs-lsp-booster
    mu
    grip
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
  };
  services.emacs = {
    enable = true;
    startWithUserSession = "graphical";
  };
}
