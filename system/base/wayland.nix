{pkgs, ...}: {
  programs.pinnacle = {
    enable = true;
    xdg-portals.enable = true;
    withUWSM = true;
  };

  # Enable the X11 windowing system
  services.xserver.enable = true;

  services.libinput = {
    enable = true;
    touchpad = {
      clickMethod = "clickfinger";
      naturalScrolling = true;
      additionalOptions = ''MatchIsTouchpad "on"'';
    };
  };
  services.xserver = {
    xkb = {
      layout = "us";
      variant = "";
    };
  };
  environment.sessionVariables = {
    DRI_PRIME = "1";
  };

  # set up the display manager
  services.displayManager = {
    defaultSession = "pinnacle-uwsm";
    autoLogin = {
      enable = true;
      user = pkgs.lib.mkForce "cassandra";
    };

    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  programs.dconf.enable = true;
  security.polkit.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
    ];
  };

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
