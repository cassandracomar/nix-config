{ config, lib, pkgs, ... }:

{
  services.tlp = {
    enable = true;
    extraConfig = ''
      CPU_SCALING_GOVERNOR_ON_AC=ondemand
      CPU_SCALING_GOVERNOR_ON_BAT=schedutil
    '';
  };
  services.acpid.enable = true;
  powerManagement.enable = true;
  powerManagement.powertop.enable = false;
}
