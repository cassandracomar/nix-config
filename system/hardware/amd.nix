{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules =
    [ "nvme" "xhci_pci" "uas" "usbhid" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "amd_pstate" "kvm_amd" "cpuid" "i2c-dev" ];
  boot.kernelParams = [ "amdgpu.backlight=0" "acpi_backlight=video" ];

  powerManagement.cpuFreqGovernor = pkgs.lib.mkDefault "ondemand";

  services.acpid.handlers = {
    brightness-down = {
      event = "video/brightnessdown";
      action = ''
        #!${pkgs.bash}/bin/bash
        ${pkgs.brightnessctl}/bin/brightnessctl -d amdgpu_bl0 s 5%-
        raw=$(${pkgs.brightnessctl}/bin/brightnessctl -d amdgpu_bl0 g)
        perc=$(${pkgs.bc}/bin/bc <<< "scale=4; 100*$raw/255")
        /run/wrappers/bin/sudo -u cassandra DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus ${pkgs.libnotify}/bin/notify-send " " -i display-brightness-symbolic.symbolic -h int:value:$perc -h string:x-canonical-private-synchronous:brightness &
      '';
    };
    brightness-up = {
      event = "video/brightnessup";
      action = ''
        #!${pkgs.bash}/bin/bash
        ${pkgs.brightnessctl}/bin/brightnessctl -d amdgpu_bl0 s 5%+
        raw=$(${pkgs.brightnessctl}/bin/brightnessctl -d amdgpu_bl0 g)
        perc=$(${pkgs.bc}/bin/bc <<< "scale=4; 100*$raw/255")
        /run/wrappers/bin/sudo -u cassandra DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus ${pkgs.libnotify}/bin/notify-send " " -i display-brightness-symbolic.symbolic -h int:value:$perc -h string:x-canonical-private-synchronous:brightness &
      '';
    };
  };
}
