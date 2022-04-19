{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    wineWowPackages.stable
    winetricks
    lutris
    vulkan-tools
    virt-viewer
    chessx
    stockfish
    # (retroarchFull.overrideAttrs
    #   (old: { cores = with libretro; (lib.remove dosbox old.cores); }))
  ];
}
