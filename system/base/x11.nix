{ config, lib, pkgs, ... }:

{
  # Enable the X11 windowing system
  services.xserver.enable = true;
  services.xserver.layout = "us";

  services.xserver = {
    deviceSection = ''
      Option "TearFree" "true"
    '';
    # Enable touchpad support.
    libinput = {
      enable = true;
      touchpad = {
        clickMethod = "clickfinger";
        naturalScrolling = true;
        additionalOptions = ''MatchIsTouchpad "on"'';
      };
    };

    # set up the display manager
    displayManager = {
      lightdm = {
        enable = true;
        greeters.gtk = {
          theme = {
            package = pkgs.qogir-theme;
            name = "Qogir-Dark";
          };
          iconTheme = {
            package = pkgs.qogir-icon-theme;
            name = "Qogir-dark";
          };
          cursorTheme = {
            package = pkgs.qogir-theme;
            name = "Qogir-dark";
          };
        };

      };
      autoLogin = {
        enable = true;
        user = "cassandra";
      };
    };
    displayManager.defaultSession = "none+xsession";

    # set up the session
    windowManager.session = pkgs.lib.singleton {
      name = "xsession";
      start = pkgs.writeScript "xsession" ''
        #!${pkgs.runtimeShell}
        if test -f $HOME/.xsession; then
          exec ${pkgs.runtimeShell} -c $HOME/.xsession
        else
          echo "No xession script found"
        fi
      '';
    };

    wacom.enable = true;
  };

  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages = with pkgs; [
    pipewire
    pulseaudioFull
    libva-utils
  ];
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [
    pipewire
    pulseaudioFull
    libva-utils
  ];
  services.picom.enable = true;
  services.picom.backend = "glx";
  services.picom.vSync = true;
  services.picom.shadowOpacity = 1.0;

  # high-resolution display
  hardware.video.hidpi.enable = pkgs.lib.mkDefault true;
  services.xserver.dpi = 144;
}
