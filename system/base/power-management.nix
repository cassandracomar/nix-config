{ config, lib, pkgs, ... }:

{
  services.tlp = { enable = true; };
  services.acpid.enable = true;
  powerManagement.enable = true;
  powerManagement.powertop.enable = false;
}
