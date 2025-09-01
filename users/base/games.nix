{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    wineWow64Packages.waylandFull
    winetricks
    lutris
    vulkan-tools
    virt-viewer
    chessx
    stockfish
    retroarchFull
  ];
}
