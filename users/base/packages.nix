{ config, lib, pkgs, pkgs-master, host, ... }:

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
    # pkgs.ocenaudio
    android-studio
    # ffmpeg-full
    # svt-av1
    # libopus
    pkgs-master.nice-dcv-client
    numactl
    arandr
    pinentry-gnome
    openconnect-sso
    openconnect
    android-tools
    rnix-lsp
    fly
  ];

  home.file.".config/discord/settings.json".text = ''
    { "SKIP_HOST_UPDATE": true }
  '';

  programs.obs-studio.enable = true;
}
