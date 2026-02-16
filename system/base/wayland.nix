{
  pkgs,
  lib,
  config,
  ...
}: {
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

  # set up the display manager
  services.displayManager = let
    cfg = config.programs.uwsm;
    mk_uwsm_desktop_entry = opts: (pkgs.writeTextFile {
      name = "${opts.name}-uwsm";
      text = ''
        [Desktop Entry]
        Name=${opts.prettyName} (UWSM)
        Comment=${opts.comment}
        Exec=${lib.getExe cfg.package} start -F -- ${opts.binPath} ${lib.strings.escapeShellArgs opts.extraArgs}
        Type=Application
      '';
      destination = "/share/wayland-sessions/${opts.name}-uwsm.desktop";
      derivationArgs = {
        passthru.providedSessions = ["${opts.name}-uwsm"];
      };
    });
    desktopEntries =
      lib.mapAttrsToList (
        name: value:
          mk_uwsm_desktop_entry {
            inherit name;
            inherit
              (value)
              prettyName
              comment
              binPath
              extraArgs
              ;
          }
      )
      cfg.waylandCompositors;
  in {
    enable = true;
    defaultSession = "pinnacle-uwsm";
    sessionPackages = desktopEntries;
    autoLogin = {
      enable = true;
      user = pkgs.lib.mkForce "cassandra";
    };

    sddm = {
      enable = true;
      wayland.enable = true;
      autoLogin.relogin = true;
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
      vulkan-hdr-layer-kwin6
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

  services.dbus = {
    implementation = "broker";
  };
}
