{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    wineWowPackages.waylandFull
    winetricks
    lutris
    virt-viewer
    chessx
    stockfish
    retroarchFull
  ];
}
