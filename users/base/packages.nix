{
  pkgs,
  inputs,
  system,
  ...
}: {
  # Let Home Manager install and manage itself.
  # programs.home-manager.enable = true;

  home.packages = with pkgs; [
    slack
    signal-desktop
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
    pinentry-rofi
    openconnect
    android-tools
    fly
    veracrypt
    nixd
  ];

  home.file.".config/discord/settings.json".text = ''
    { "SKIP_HOST_UPDATE": true }
  '';

  programs.obs-studio.enable = true;
  programs.man.generateCaches = true;
}
