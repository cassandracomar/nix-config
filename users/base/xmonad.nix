{ config, lib, pkgs, nixpkgs, haskellNix, system, ... }:
let
  haskellPackages = (haskellNix.internal.compat { inherit system; }).pkgs.haskellPackages;

in
{
  home.packages = with pkgs; [
    dmenu
    dzen2
    conky
    trayer
    cbatticon
    gnome.adwaita-icon-theme
    qogir-theme
    maim
    (writeScriptBin "screenshot" ''
      #!${bash}/bin/bash
      ${maim}/bin/maim -s ~/imgs/screenshots/$(date "+%F-%H-%M-%S")_maim.png
    '')
    ispell
    # gnome.gnome-calculator
    lxappearance
    usbutils
    xorg.xev
    brightnessctl
    gptfdisk
    bind
    vlc
    pinta
  ];

  home.pointerCursor.package = pkgs.vanilla-dmz;
  home.pointerCursor.name = "Vanilla-DMZ";
  xsession = {
    enable = true;
    windowManager = {
      xmonad = {
        inherit haskellPackages;
        enable = true;
        enableContribAndExtras = true;
      };
    };
    initExtra = ''
      ${pkgs.feh}/bin/feh --bg-fill /home/cassandra/wallpapers/haskell-wallpaper.png
      cbatticon &
    '';
  };

  programs.feh.enable = true;
  programs.jq.enable = true;
  programs.autorandr = {
    enable = true;
    hooks = {
      postswitch = {
        "notify-xmonad" = "xmonad --restart";
        "change-background" =
          "${pkgs.feh}/bin/feh --bg-fill /home/cassandra/wallpapers/haskell-wallpaper.png";
        "reset-dpms" = ''
          #! ${pkgs.bash}/bin/bash
          if [[ $(${pkgs.autorandr}/bin/autorandr --detected | grep undocked) == "undocked" ]]; then
            ${pkgs.xorg.xset}/bin/xset s on +dpms
          else
            ${pkgs.xorg.xset}/bin/xset s off -dpms
          fi
        '';
      };
    };
  };

  services.dunst = {
    enable = true;
    iconTheme.name = "Adwaita";
    iconTheme.package = pkgs.gnome.adwaita-icon-theme;
    settings = {
      global = {
        geometry = "600x3-0+40";
        markup = "full";
      };
    };
  };

  # services.betterlockscreen = {
  #   enable = true;
  #   inactiveInterval = 15;
  # };

  programs.zathura = { enable = true; };
}
