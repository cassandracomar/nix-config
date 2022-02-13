{ config, lib, pkgs, ... }:

{
  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "overlay2";
      daemon.settings = {
        bip = "172.16.0.100/24";
        dns = [ "127.0.0.1" ];
      };
    };
    libvirtd.enable = true;
  };
}
