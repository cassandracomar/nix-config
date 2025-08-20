{ pkgs, ... }: {
  home.sessionVariables._JAVA_AWT_WM_NONREPARENTING = "1";
  home.sessionVariables.MOZ_ACCELERATED = "1";
  home.sessionVariables.MOZ_WEBRENDER = "1";
  home.sessionVariables.EDITOR = "${pkgs.emacs-pgtk}/bin/emacsclient -t";
  home.sessionVariables.VISUAL = "${pkgs.emacs-pgtk}/bin/emacsclient -c";
  home.sessionVariables.ALTERNATE = "vim";
  home.sessionVariables.XDG_DATA_DIRS = "$HOME/.nix-profile/share:$XDG_DATA_DIRS";
  home.sessionVariables.PATH = "$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.doom-emacs.d/bin:$HOME/.emacs.d/bin:$HOME/.krew/bin:$PATH";

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv = {enable = true;};
  };
}
