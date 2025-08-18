{pkgs, ...}: {
  programs.pinnacle = {
    enable = true;
    xdg-portals.enable = true;
    withUWSM = true;
  };

  # Enable the X11 windowing system
  services.xserver.enable = true;
  services.xserver.layout = "us";

  services.xserver = {
    # Enable touchpad support.
    libinput = {
      enable = true;
      touchpad = {
        clickMethod = "clickfinger";
        naturalScrolling = true;
        additionalOptions = ''MatchIsTouchpad "on"'';
      };
    };
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # set up the display manager
  services.displayManager = {
    defaultSession = "pinnacle-uwsm";
    autoLogin = {
      enable = true;
      user = "cassandra";
    };

    sddm = {
      enable = true;
      wayland = true;
    };
  };

  programs.dconf.enable = true;
  security.polkit.enable = true;

  hardware.graphics.enable = true;

  security.pam.loginLimits = [
    {
      domain = "@users";
      item = "rtprio";
      type = "-";
      value = 1;
    }
  ];

  services.gvfs = {
    enable = true;
  };
}
