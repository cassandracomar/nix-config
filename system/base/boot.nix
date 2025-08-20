{
  config,
  lib,
  pkgs,
  ...
}: {
  # set ZFS options
  boot.supportedFilesystems = ["zfs" "f2fs" "ext4" "xfs" "cifs" "vfat" "ntfs"];
}
