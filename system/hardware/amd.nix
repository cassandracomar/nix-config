{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules =
    [ "nvme" "xhci_pci" "uas" "usbhid" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "amd_pstate" "kvm_amd" "cpuid" "i2c-dev" ];
  boot.kernelParams = [ "amdgpu.backlight=0" "acpi_backlight=video" ];

  powerManagement.cpuFreqGovernor = pkgs.lib.mkDefault "schedutil";

  services.acpid.handlers = {
    brightness-down = {
      event = "video/brightnessdown";
      action = ''
        ${pkgs.brightnessctl}/bin/brightnessctl -d amdgpu_bl1 s 5%-
        perc=$(${pkgs.brightnessctl}/bin/brightnessctl -d amdgpu_bl1 -get)
        ${pkgs.libnotify}/bin/notify-send " " -i notification-display-brightness-low -h int:value:$perc -h string:x-canonical-private-synchronous:brightness &
      '';
    };
    brightness-up = {
      event = "video/brightnessup";
      action = ''
        ${pkgs.brightnessctl}/bin/brightnessctl -d amdgpu_bl1 s 5%+
        perc=$(${pkgs.brightnessctl}/bin/brightnessctl -d amdgpu_bl1 -get)
        ${pkgs.libnotify}/bin/notify-send " " -i notification-display-brightness-low -h int:value:$perc -h string:x-canonical-private-synchronous:brightness &
      '';
    };
  };
}
