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
  boot.extraModprobeConfig = ''
    options zfs metaslab_lba_weighting_enabled=0 zfs_vdev_sync_write_min_active=10  zfs_vdev_sync_write_max_active=32  zfs_vdev_async_write_min_active=10  zfs_vdev_async_write_max_active=32
  '';
  # boot.zfs.package = lib.mkAfter pkgs-master.zfsUnstable;
}
