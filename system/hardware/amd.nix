{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules =
    [ "nvme" "xhci_pci" "uas" "usbhid" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "amd_pstate" "kvm_amd" "cpuid" "i2c-dev" ];
  boot.kernelParams = [ "amdgpu.backlight=0" "acpi_backlight=video" ];

  powerManagement.cpuFreqGovernor = pkgs.lib.mkDefault "schedutil";
}
