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
    vulkan-tools
    virt-viewer
    chessx
    stockfish
    retroarchFull
  ];
}
