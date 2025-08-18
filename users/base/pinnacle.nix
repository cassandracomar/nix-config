{pkgs, ...}: {
  wayland.windowManager.pinnacle = {
    enable = true;
    package = pkgs.pinnacle-config;
    systemd = {
      enable = true;
      # use UWSM instead
      useService = false;
      xdgAutostart = true;
    };
  };

  services.walker = {
    enable = true;
    systemd.enable = true;
  };

  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      enableDebug = true;
      enableInspect = true;
    };
  };
  programs.feh.enable = true;
  programs.jq.enable = true;
  programs.wezterm = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = {}

      config.color_scheme = 'Monokai (dark) (terminal.sexy)'
      config.colors = {
        background = '#171717',
        foreground = '#d6d6d1'
      }
      config.font = wezterm.font('Iosevka Nerd Font')
      config.font_size = 18
      config.window_decorations  = "RESIZE | MACOS_FORCE_DISABLE_SHADOW"
      config.use_fancy_tab_bar = false
      config.show_new_tab_button_in_tab_bar = false
      config.default_cursor_style = 'SteadyBar'
      config.enable_tab_bar = false
      config.window_padding = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
      }

      return config
    '';
  };

  home.packages = with pkgs; [
    pinnacle
    pinnacle-config
    gnome.adwaita-icon-theme
    qogir-theme
    gnome.gnome-calculator
    lxappearance
    vlc
    pinta
    usbutils
    gptfdisk
    bind
  ];

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
