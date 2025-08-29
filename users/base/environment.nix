{ pkgs, config, ... }: {
  home.sessionVariables = {
    _JAVA_AWT_WM_NONREPARENTING = "1";
    MOZ_ACCELERATED = "1";
    MOZ_WEBRENDER = "1";
    MOZ_ENABLE_WAYLAND = "1";
    EDITOR = "${pkgs.emacs-igc-pgtk}/bin/emacsclient -t";
    VISUAL = "${pkgs.emacs-igc-pgtk}/bin/emacsclient -c";
    ALTERNATE = "vim";
    DRI_PRIME = "1";
    FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
    ROFI_SCREENSHOT_DIR = "${config.xdg.userDirs.pictures}/screenshots";
  };

  home.sessionPath = ["${config.home.homeDirectory}/.cargo/bin" "${config.home.homeDirectory}/.local/bin" "${config.home.homeDirectory}/krew/bin"];
  xdg.systemDirs.data = ["$HOME/.nix-profile/share"];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    pictures = "${config.home.homeDirectory}/images";
    download = "${config.home.homeDirectory}/downloads";
    videos = "${config.home.homeDirectory}/videos";
    documents = "${config.home.homeDirectory}/docs";
    desktop = "${config.home.homeDirectory}/desktop";
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv = {enable = true;};
  };
}
