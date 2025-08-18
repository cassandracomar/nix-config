{
  config,
  lib,
  pkgs,
  ...
}: {
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
  nix.settings.trusted-users = ["root" "cassandra"];
  nix.settings.experimental-features = ["nix-command" "flakes"];

  users.users.root = {shell = pkgs.zsh;};

  security.sudo.enable = true;
  security.sudo.extraConfig = ''
    %wheel	ALL=(ALL:ALL)	NOPASSWD:	ALL
  '';

  boot.kernel.sysctl = {
    "kernel.pty.max" = 8192;
    "kernel.pty.reserve" = 8192;
    "fs.file-max" = 1048576;
    "fs.inotify.max_user_instances" = 65535;
    "fs.inotify.max_user_watches" = 16777215;
    "fs.nr_open" = 16777216;
  };
  #systemd.services."user@1000".serviceConfig.LimitNOFILE = "1073741816";
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "1048576";
    }
  ];
}
