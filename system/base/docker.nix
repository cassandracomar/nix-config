{ config, lib, pkgs, ... }:

{
  virtualisation = {
    docker = {
      enable = true;
      # extraPackages = [ pkgs.zfsUnstable pkgs.fuse-overlayfs ];
      # dockerSocket.enable = true;
      storageDriver = lib.mkDefault "zfs";
      daemon.settings = {
        bip = "172.16.0.100/24";
        # dns = [ "127.0.0.11" ];
      };
    };
    libvirtd.enable = true;
    # containers.storage.settings = {
    #   storage = {
    #     driver = "zfs";
    #     graphroot = "/var/lib/containers/storage";
    #     runroot = "/run/containers/storage";
    #     options.zfs = {
    #       fsname = "data/root/containers";
    #     };
    #   };
    # };
  };
}
