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
    (retroarch.withCores (cores:
      with cores; [
        desmume
        mgba
        pcsx2
        ppsspp-sdl-wayland
        pcsx-rearmed
      ]))
  ];
}
