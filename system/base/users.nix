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

  boot.kernel.sysctl = {
    "kernel.pty.max" = 8192;
    "kernel.pty.reserve" = 8192;
  };
  #systemd.services."user@1000".serviceConfig.LimitNOFILE = "1073741816";
  # security.pam.loginLimits = [
  #   {
  #     domain = "root";
  #     type = "-";
  #     item = "nofile";
  #     value = "unlimited";
  #   }
  #   {
  #     domain = "*";
  #     type = "-";
  #     item = "nofile";
  #     value = "unlimited";
  #   }
  # ];

}
