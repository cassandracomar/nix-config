{ config, lib, pkgs, pkgs-master, ... }:

{
  # Let Home Manager install and manage itself.
  # programs.home-manager.enable = true;

  home.packages = with pkgs; [
    slack
    zoom-us
    signal-desktop
    monero
    monero-gui
    keepassxc
    google-chrome
    discord
    nodePackages.bash-language-server
    spotify
    curlFull
    rclone
    syncthing
    dbus
    terraform
    nyxt
    xclip
    sbcl
    lilypond
    reaper
    evtest
    audacity
    pkgs-master.ocenaudio
    android-studio
  ];

  home.file.".config/discord/settings.json".text = ''
    { "SKIP_HOST_UPDATE": true }
  '';

  programs.obs-studio.enable = true;
  services.syncthing.enable = true;
}
