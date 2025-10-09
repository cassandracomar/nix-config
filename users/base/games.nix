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
        (pcsx2.overrideAttrs (old: {
          cmakeFlags = (old.cmakeFlags or []) ++ ["-DCMAKE_POLICY_VERSION_MINIMUM=3.10"];
        }))
        ppsspp
        pcsx-rearmed
      ]))
  ];
}
