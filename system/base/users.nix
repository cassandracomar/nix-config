{ config, lib, pkgs, ... }:

{
  users.users.cassandra = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "sound"
      "docker"
      "libvirtd"
      "transmission"
      "jackaudio"
      "adbusers"
    ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
  };
  nix.settings.trusted-users = [ "root" "cassandra" ];

  users.users.root = { shell = pkgs.zsh; };

  security.sudo.enable = true;
  security.sudo.extraConfig = ''
    %wheel	ALL=(ALL:ALL)	NOPASSWD:	ALL
  '';

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "2147483648";
    }
  ];

}
