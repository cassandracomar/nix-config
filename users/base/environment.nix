{ pkgs, ... }: {
  home.sessionVariables = {
    _JAVA_AWT_WM_NONREPARENTING = "1";
    MOZ_ACCELERATED = "1";
    MOZ_WEBRENDER = "1";
    MOZ_ENABLE_WAYLAND = "1";
    EDITOR = "${pkgs.emacs-pgtk}/bin/emacsclient -t";
    VISUAL = "${pkgs.emacs-pgtk}/bin/emacsclient -c";
    ALTERNATE = "vim";
    DRI_PRIME = "1";
    FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
  };
  home.sessionPath = ["$HOME/.cargo/bin" "$HOME/.local/bin" "$HOME/krew/bin"];
  xdg.systemDirs.data = ["$HOME/.nix-profile/share"];

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv = {enable = true;};
  };
}
