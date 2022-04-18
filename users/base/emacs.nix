{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    sqlite
    direnv
    p7zip
    unrar
    unzip
    nixfmt
    ripgrep
    pandoc
    nodePackages.bash-language-server
    yaml-language-server
    nodePackages.dockerfile-language-server-nodejs
    gcc
    gnumake
  ];

  systemd.user.startServices = true;

  programs.emacs = {
    enable = true;
    package = pkgs.emacsPgtkGcc;
    extraPackages = epkgs:
      with pkgs; [
        lilypond
        timidity
        sqlite
        binutils_nogold
        gcc
        gnumake
        epkgs.vterm
        epkgs.sqlite3
        epkgs.emacsql
        epkgs.emacsql-sqlite3
      ];
  };
  services.emacs.enable = true;
}
