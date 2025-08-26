{ pkgs, ... }: {
  home.sessionVariables._JAVA_AWT_WM_NONREPARENTING = "1";
  home.sessionVariables.MOZ_ACCELERATED = "1";
  home.sessionVariables.MOZ_WEBRENDER = "1";
  home.sessionVariables.EDITOR = "${pkgs.emacs-pgtk}/bin/emacsclient -t";
  home.sessionVariables.VISUAL = "${pkgs.emacs-pgtk}/bin/emacsclient -c";
  home.sessionVariables.ALTERNATE = "vim";
  home.sessionPath = ["$HOME/.cargo/bin" "$HOME/.local/bin" "$HOME/krew/bin"];
  xdg.systemDirs = ["$HOME/.nix-profile/share"];
  home.sessionVariables.DRI_PRIME = "1";

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv = {enable = true;};
  };
}
