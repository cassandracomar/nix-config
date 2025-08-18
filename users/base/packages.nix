{
  config,
  lib,
  pkgs,
  host,
  ...
}: {
  # Let Home Manager install and manage itself.
  # programs.home-manager.enable = true;

  home.packages = with pkgs; [
    slack
    zoom-us
    signal-desktop
    monero-cli
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
    xclip
    lilypond
    reaper
    evtest
    audacity
    # pkgs.ocenaudio
    android-studio
    # ffmpeg-full
    # svt-av1
    # libopus
    numactl
    arandr
    pinentry-gnome3
    openconnect-sso
    openconnect
    android-tools
    rnix-lsp
    fly
    veracrypt
  ];

  home.file.".config/discord/settings.json".text = ''
    { "SKIP_HOST_UPDATE": true }
  '';

  programs.obs-studio.enable = true;
}
