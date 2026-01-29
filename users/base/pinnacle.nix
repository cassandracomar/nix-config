{
  pkgs,
  lib,
  pinnacle-config,
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
    rofi-emoji
    rofi-file-browser
    rofi-power-menu
  ];
  rofi-packages = with pkgs; [
    rofi-bluetooth
    clerk
    rofi-rbw-wayland
    rofi-pulse-select
    rofi-screenshot
    rofi-systemd
    rofi-vpn
  ];
  uwsm-run = pkgs.writeScriptBin "uwsm-run" ''
    #!${pkgs.runtimeShell}
    app_name=$(echo "$@" | cut -d" " -f 1 | xargs basename)
    exec uwsm app -a "''${app_name}" -- systemd-cat "$@"
  '';
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
      useService = lib.mkDefault false;
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
    plugins = rofi-plugins;
    cycle = true;
    font = "Iosevka Nerd Font 32";
    location = "top";
    pass = {
      enable = false;
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
      run-command = "${uwsm-run}/bin/uwsm-run {cmd}";
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
      config.integrated_title_buttons = {}
      config.tiling_desktop_environments = {'Wayland'}
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
    configDir = ./eww;
  };

  systemd.user.services = {
    eww-daemon = {
      Unit = {
        Description = "eww daemon user service";
        BindsTo = ["graphical-session.target"];
        Wants = ["graphical-session-pre.target" "wayland-wm@pinnacle.service" "pinnacle.service"];
        After = ["graphical-session-pre.target" "wayland-wm@pinnacle.service" "pinnacle.service"];
        X-SwitchMethod = "reload";
        StartLimitIntervalSec = 0;
      };
      Service = {
        Slice = ["session.slice"];
        Type = "exec";
        ExecStart = "${pkgs.eww}/bin/eww daemon --no-daemonize";
        ExecReload = "${pkgs.eww}/bin/eww reload --no-daemonize";
        Restart = "on-failure";
        RestartSec = "1s";
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
    "eww-open@" = {
      Unit = {
        Description = "launch eww windows for the output";
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.eww}/bin/eww open --no-daemonize --screen %i primary --arg monitor=%i";
        ExecStop = "${pkgs.eww}/bin/eww close --no-daemonize primary";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "1s";
      };
      Install = {
        WantedBy = pkgs.lib.mkForce [];
      };
    };
  };

  home.packages = with pkgs;
    rofi-packages
    ++ [
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
      uwsm
      uwsm-run
      wdisplays
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
    iconTheme = {
      name = "Qogir-Dark";
      package = pkgs.qogir-icon-theme;
      size = "32@2x";
    };
    settings = {
      global = {
        follow = "keyboard";

        # geometry
        width = "(100, 300)";
        height = "(0, 300)";
        origin = "top-right";
        offset = "(5, 15)";
        scale = 0;
        notification_limit = 10;

        progress_bar = true;
        progress_bar_height = 14;
        progress_bar_frame_width = 0;
        progress_bar_min_width = 100;
        progress_bar_max_width = 300;
        progress_bar_corner_radius = 50;
        progress_bar_corners = "bottom-left, top-right";

        icon_corner_radius = 0;
        icon_corners = "all";
        indicate_hidden = "yes";

        transparency = 0;
        separator_height = 6;
        padding = 10;
        horizontal_padding = 8;
        text_icon_padding = 12;
        frame_width = 1;
        frame_color = "#a0a0a0";
        gap_size = 6;

        separator_color = "frame";
        sort = "yes";

        font = "Iosevka Nerd Font 16";
        line_height = 0;
        markup = "full";
        format = "<b>%s</b>\\n%b";
        alignment = "left";
        vertical_alignment = "center";
        show_age_threshold = -1;

        ignore_newline = "no";
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = "yes";

        icon_position = "right";
        min_icon_size = 32;
        max_icon_size = 128;
        history_length = 30;
        corner_radius = 10;
        corners = "bottom, top-left";

        ignore_dbusclose = false;
      };

      experimental = {
        per_monitor_dpi = true;
      };

      urgency_low = {
        background = "#222222";
        foreground = "#ffffff";
        highlight = "#722ae6, #e4b5cb";
        timeout = 20;
      };

      urgency_normal = {
        background = "#222222";
        foreground = "#ffffff";
        frame_color = "#525086";
        highlight = "#722ae6, #e4b5cb";
        timeout = 20;
        override_pause_level = 30;
        default_icon = "dialog-information";
      };

      urgency_critical = {
        background = "#222222";
        foreground = "#ffffff";
        frame_color = "#d54e53";
        highlight = "#d54e53, #f0f0f0";
        timeout = 0;
        override_pause_level = 60;
        default_icon = "dialog-warning";
      };
    };
  };

  programs.zathura.enable = true;
}
