{ config, lib, pkgs, ... }:

{

  home.sessionVariables._JAVA_AWT_WM_NONREPARENTING = "1";
  home.sessionVariables.MOZ_ACCELERATED = "1";
  home.sessionVariables.MOZ_WEBRENDER = "1";
  home.sessionVariables.EDITOR = "${pkgs.emacsPgtkGcc}/bin/emacsclient -t";
  home.sessionVariables.VISUAL = "${pkgs.emacsPgtkGcc}/bin/emacsclient -c";
  home.sessionVariables.ALTERNATE = "vim";
  home.sessionVariables.XDG_DATA_DIRS =
    "$HOME/.nix-profile/share:$XDG_DATA_DIRS";
  home.sessionVariables.PATH =
    "$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.doom-emacs.d/bin:$HOME/.emacs.d/bin:$HOME/.krew/bin:$PATH";
  home.sessionVariables.GDK_SCALE = "2";
  home.sessionVariables.GDK_DPI_SCALE = "0.5";

  xresources.extraConfig = ''
    Xft.dpi: 200
    Xft.autohint: 0
    Xft.lcdfilter: lcddefault
    Xft.hintstyle: hintfull
    Xft.hinting: 1
    Xft.antialias: 1
    Xft.rgba: rgb
  '';

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv = { enable = true; };
  };

}
