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
        epkgs.vterm
        epkgs.emacsql-sqlite3
      ];
  };
  services.emacs.enable = true;
}
