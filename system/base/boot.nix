{ config, lib, pkgs, pkgs-master, ... }:

{

  # set ZFS options
  boot.supportedFilesystems =
    [ "zfs" "f2fs" "ext4" "xfs" "cifs" "vfat" "ntfs" ];
  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot.enable = true;
    trim.enable = true;
  };
  boot.zfs.enableUnstable = true;
  # boot.zfs.package = lib.mkAfter pkgs-master.zfsUnstable;
}
