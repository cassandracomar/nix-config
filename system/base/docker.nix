{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.podman ];
  virtualisation = {
    podman = {
      enable = true;
      extraPackages = [ pkgs.zfsUnstable ];
      dockerSocket.enable = true;
      # storageDriver = lib.mkDefault "zfs";
      # daemon.settings = {
      #   bip = "172.16.0.100/24";
      #   dns = [ "127.0.0.11" ];
      # };
    };
    libvirtd.enable = true;
  };
}
