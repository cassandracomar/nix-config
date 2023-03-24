{ config, lib, pkgs, ... }:

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
    options zfs metaslab_lba_weighting_enabled=0 zfs_vdev_sync_write_min_active=10  zfs_vdev_sync_write_max_active=32  zfs_vdev_async_write_min_active=10  zfs_vdev_async_write_max_active=32 l2arc_headroom=0 l2arc_rebuild_enabled=1 l2arc_exclude_special=0 l2arc_trim_ahead=20
  '';
}
