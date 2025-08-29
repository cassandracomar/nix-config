{
  pkgs,
  pinnacle-config,
  config,
  ...
}: let
  rofi-themes-collection = pkgs.fetchFromGitHub {
    owner = "newmanls";
    repo = "rofi-themes-collection";
    rev = "ec731cef79d39fc7ae12ef2a70a2a0dd384f9730";
    sha256 = "sha256-96wSyOp++1nXomnl8rbX5vMzaqRhTi/N7FUq6y0ukS8=";
  };
  rofi-plugins = with pkgs; [
    rofi-calc
    rofi-games
    rofi-emoji-wayland
    rofi-file-browser
    rofi-power-menu
  ];
  rofi-packages = with pkgs; [
    rofi-bluetooth
    (clerk.override {rofi = rofi-wayland;})
    rofi-rbw-wayland
    (rofi-pulse-select.override {rofi-unwrapped = rofi-wayland-unwrapped;})
    (rofi-screenshot.override {rofi = rofi-wayland;})
    (rofi-systemd.override {rofi = rofi-wayland;})
    (rofi-vpn.override {rofi-unwrapped = rofi-wayland-unwrapped;})
  ];
in {
  wayland.windowManager.pinnacle = {
    enable = true;
    clientPackage = pkgs.pinnacle.buildRustConfig {
      pname = "pinnacle-config";
      version = "0.1.0";
      src = pinnacle-config;
    };
    systemd = {
      enable = true;
      # use UWSM instead
      useService = false;
      xdgAutostart = true;
    };
    extraSettings = {
      env = {
        FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
      };
    };
  };

  services.wpaperd = {
    enable = true;
    settings = {
      any = {
        path = ../../wallpapers;
      };
    };
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    plugins = rofi-plugins;
    cycle = true;
    font = "Iosevka Nerd Font 32";
    location = "top";
    pass = {
      enable = true;
      package = pkgs.rofi-pass-wayland;
    };
    terminal = "${pkgs.wezterm}/bin/wezterm";
    theme = "${rofi-themes-collection}/themes/rounded-pink-dark.rasi";
    extraConfig = {
      threads = 0;
      scroll-method = 1;
      case-smart = true;
      cycle = true;
      normalize-match = true;
      no-lazy-grab = true;
      show-icons = true;
      markup = true;
      transient-window = true;
      matching = "fuzzy";
      steal-focus = true;
      sidebar-mode = true;
      monitor = -4;
      dpi = 96;
    };
  };

  home.pointerCursor = {
    enable = true;
    dotIcons.enable = true;
    gtk.enable = true;
    x11 = {
      enable = true;
      defaultCursor = "left_ptr";
    };
    name = "Qogir-Dark";
    package = pkgs.qogir-icon-theme;
    size = 24;
  };
  gtk = {
    enable = true;
    iconTheme = {
      name = "Qogir-Dark";
      package = pkgs.qogir-icon-theme;
    };
    theme = {
      name = "Qogir-Dark";
      package = pkgs.qogir-theme;
    };
  };
  qt = {
    enable = true;
    style = {
      name = "Qogir-Dark";
      package = pkgs.qogir-kde;
    };
  };

  programs.feh.enable = true;
  programs.jq.enable = true;
  programs.wezterm = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    extraConfig = ''
      local config = {}

      config.default_prog = { 'nu', '--config', '~/.config/nushell/wezterm-config.nu', '--env-config', '~/.config/nushell/env.nu' }
      config.color_scheme = 'Monokai (dark) (terminal.sexy)'
      config.colors = {
        background = '#171717',
        foreground = '#d6d6d1'
      }
      config.font = wezterm.font('Iosevka Nerd Font')
      config.font_size = 16
      config.window_decorations  = "NONE"
      config.use_fancy_tab_bar = false
      config.show_new_tab_button_in_tab_bar = false
      config.default_cursor_style = 'SteadyBar'
      config.enable_tab_bar = false
      config.window_padding = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 16,
      }

      return config
    '';
  };

  programs.eww = {
    enable = true;
    package = pkgs.eww;
    configDir = ./eww;
  };

  home.packages = with pkgs;
    rofi-packages
    ++ [
      pinnacle
      adwaita-icon-theme
      qogir-theme
      gnome-calculator
      lxappearance
      vlc
      pinta
      usbutils
      gptfdisk
      bind
      rofi-pass-wayland
      go # oh-my-posh demands this, sigh
      xwayland
      wl-clipboard-rs
      wl-restart
      wl-screenrec
      wl-color-picker
      wlprop
      pulseaudio
    ];

  services.clipcat = {
    enable = true;
    enableSystemdUnit = true;
    menuSettings = {
      finder = "rofi";
    };
  };

  services.dunst = {
    enable = true;
    iconTheme.name = "Qogir";
    iconTheme.package = pkgs.qogir-icon-theme;
    settings = {
      global = {
        geometry = "600x3-0+40";
        markup = "full";
      };
    };
  };

  programs.zathura.enable = true;
}
