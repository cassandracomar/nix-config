{ config, lib, pkgs, pkgs-master, ... }:

{
  boot.loader = {
    # systemd-boot = {
    #   enable = true;
    #   configurationLimit = 5;
    # };
    efi = {
      canTouchEfiVariables = true;
      # assuming /boot is the mount point of the  EFI partition in NixOS (as the installation section recommends).
      efiSysMountPoint = "/boot";
    };
    grub = {
      devices = [ "/dev/nvme0n1" ];
      efiSupport = true;
      enable = true;
      version = 2;
      useOSProber = true;
      copyKernels = true;
      configurationLimit = 5;
      zfsSupport = true;
    };
  };

  # set ZFS options
  boot.supportedFilesystems =
    [ "zfs" "f2fs" "ext4" "xfs" "cifs" "vfat" "ntfs" ];
  services.zfs.autoScrub.enable = true;
  services.zfs.autoSnapshot.enable = true;
  boot.zfs.enableUnstable = true;
  # boot.zfs.package = lib.mkAfter pkgs-master.zfsUnstable;
}
