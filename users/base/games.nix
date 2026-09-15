{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    wineWow64Packages.stagingFull
    winetricks
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
  programs.lutris = {
    enable = true;
    defaultWinePackage = pkgs.wineWow64Packages.stagingFull;
    winePackages = with pkgs; [wineWow64Packages.stagingFull wineWow64Packages.waylandFull];
    protonPackages = with pkgs; [proton-ge-bin];
  };
}
