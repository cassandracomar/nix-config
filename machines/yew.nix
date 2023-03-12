# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ../system/hardware/amd.nix
    ../system/hardware/acpid.nix
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" "nct6775" "it87" ];
  boot.kernelParams = [ "nr_hugepages=4096" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.it87 ];
  boot.extraModprobeConfig = ''
    options zfs l2arc_headroom=0
  '';
  boot.zfs.extraPools = [ "data" ];
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi = {
      canTouchEfiVariables = true;
      # assuming /boot is the mount point of the  EFI partition in NixOS (as the installation section recommends).
      efiSysMountPoint = "/boot";
    };
  };

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/56bf7cf3-5c55-47bf-8aed-47be50a1f0b1";
      fsType = "f2fs";
      options = [
        "compress_algorithm=zstd"
        "compress_chksum"
        "atgc"
        "gc_merge"
        "lazytime"
        "inline_xattr"
      ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/D2EC-879D";
      fsType = "vfat";
    };
  hardware.enableRedistributableFirmware = true;

  swapDevices = [ ];

  networking.hostName = "yew"; # Define your hostname.
  networking.hostId = "c667b97b";


  #virtualisation.docker.storageDriver = "overlay2";

  powerManagement.cpuFreqGovernor = pkgs.lib.mkForce "ondemand";
  environment.systemPackages = with pkgs; [
    freeipmi
    dmidecode
    cpuid
    cpu-x
    lm_sensors
  ];

  services.openssh.enable = true;
  # services.xrdp.enable = true;

  services.xserver.deviceSection = ''
    BusId "PCI:23:00:0"
  '';
}
