{pkgs, pinnacle-config, ...}: let
  rofi-themes-collection = pkgs.fetchFromGitHub {
    owner = "newmanls";
    repo = "rofi-themes-collection";
    rev = "ec731cef79d39fc7ae12ef2a70a2a0dd384f9730";
    sha256 = "sha256-96wSyOp++1nXomnl8rbX5vMzaqRhTi/N7FUq6y0ukS8=";
  };
  rofi-packages = with pkgs; [
    rofi-bluetooth
    rofi-calc
    rofi-mpd
    rofi-emoji-wayland
    rofi-games
    rofi-power-menu
    rofi-rbw-wayland
    rofi-pulse-select
    rofi-screenshot
    rofi-systemd
    rofi-vpn
  ];
in {
  wayland.windowManager.pinnacle = {
    enable = true;
    package = pkgs.pinnacle.buildRustConfig {
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
    plugins = rofi-packages;
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

  gtk = {
    enable = true;
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
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

  programs.ironbar = {
    enable = true;
    systemd = true;
    style = pkgs.writeText "ironbar.css" ''
      @define-color color_bg #2d2d2d;
      @define-color color_bg_dark #1c1c1c;
      @define-color color_border #424242;
      @define-color color_border_active #6699cc;
      @define-color color_text #ffffff;
      @define-color color_urgent #8f0a0a;

      /* -- base styles -- */

      * {
          font-family: Iosevka Nerd Font, monospace;
          font-size: 16px;
          border: none;
          border-radius: 0;
      }

      box, menubar, button {
          background-color: @color_bg;
          background-image: none;
          box-shadow: none;
      }

      button, label {
          color: @color_text;
      }

      button:hover {
          background-color: @color_bg_dark;
      }

      scale trough {
          min-width: 1px;
          min-height: 2px;
      }

      #bar {
          border-top: 1px solid @color_border;
      }

      .popup {
          border: 1px solid @color_border;
          padding: 1em;
      }


      /* -- clipboard -- */

      .clipboard {
          margin-left: 5px;
          font-size: 1.1em;
      }

      .popup-clipboard .item {
          padding-bottom: 0.3em;
          border-bottom: 1px solid @color_border;
      }


      /* -- clock -- */

      .clock {
          font-weight: bold;
          margin-left: 5px;
      }

      .popup-clock .calendar-clock {
          color: @color_text;
          font-size: 2.5em;
          padding-bottom: 0.1em;
      }

      .popup-clock .calendar {
          background-color: @color_bg;
          color: @color_text;
      }

      .popup-clock .calendar .header {
          padding-top: 1em;
          border-top: 1px solid @color_border;
          font-size: 1.5em;
      }

      .popup-clock .calendar:selected {
          background-color: @color_border_active;
      }


      /* -- launcher -- */

      .launcher .item {
          margin-right: 4px;
      }

      .launcher .ifix examtem:not(.focused):hover {
          background-color: @color_bg_dark;
      }

      .launcher .open {
          border-bottom: 1px solid @color_text;
      }

      .launcher .focused {
          border-bottom: 1px solid @color_border_active;
      }

      .launcher .urgent {
          border-bottom-color: @color_urgent;
      }

      .popup-launcher {
          padding: 0;
      }

      .popup-launcher .popup-item:not(:first-child) {
          border-top: 1px solid @color_border;
      }


      /* -- music -- */

      .music:hover * {
          background-color: @color_bg_dark;
      }

      .popup-music .album-art {
          margin-right: 1em;
      }

      .popup-music .icon-box {
          margin-right: 0.4em;
      }

      .popup-music .title .icon, .popup-music .title .label {
          font-size: 1.7em;
      }

      .popup-music .controls *:disabled {
          color: @color_border;
      }

      .popup-music .volume .slider slider {
          border-radius: 100%;
      }

      .popup-music .volume .icon {
          margin-left: 4px;
      }

      .popup-music .progress .slider slider {
          border-radius: 100%;
      }

      /* notifications */

      .notifications .count {
          font-size: 0.6rem;
          background-color: @color_text;
          color: @color_bg;
          border-radius: 100%;
          margin-right: 3px;
          margin-top: 3px;
          padding-left: 4px;
          padding-right: 4px;
          opacity: 0.7;
      }

      /* -- script -- */

      .script {
          padding-left: 10px;
      }


      /* -- sys_info -- */

      .sysinfo {
          margin-left: 10px;
      }

      .sysinfo .item {
          margin-left: 5px;
      }


      /* -- tray -- */

      .tray {
          margin-left: 10px;
      }

      /* -- volume -- */

      .popup-volume .device-box {
          border-right: 1px solid @color_border;
      }

      /* -- workspaces -- */

      .workspaces .item.focused {
          box-shadow: inset 0 -3px;
          background-color: @color_bg_dark;
      }

      .workspaces .item.urgent {
          background-color: @color_urgent;
      }

      .workspaces .item:hover {
          box-shadow: inset 0 -3px;
      }


      /* -- custom: power menu -- */

      .popup-power-menu #header {
          font-size: 1.4em;
          padding-bottom: 0.4em;
          margin-bottom: 0.6em;
          border-bottom: 1px solid @color_border;
      }

      .popup-power-menu .power-btn {
          border: 1px solid @color_border;
          padding: 0.6em 1em;
      }

      .popup-power-menu #buttons > *:nth-child(1) .power-btn {
          margin-right: 1em;
      }
    '';
    config = {
      "position" = "top";
      "height" = 32;
      "start" = [
        {
          "type" = "workspaces";
          "all_monitors" = false;
          "name_map" = {
            "I" = "";
            "II" = "icon:firefox";
            "III" = "󰍡";
            "IV" = "icon:wezterm";
            "VI" = "icon:wezterm";
            "IX" = "icon:steam";
          };
        }
      ];
      "center" = [{
        "type" = "focused";
        "show_icon" = true;
        "show_title" = true;
        "icon_size" = 24;
        "truncate" = "end";
      }];
      "end" = [
        {
          "type" = "sys_info";
          "interval" = {
            "memory" = 30;
            "cpu" = 1;
            "temps" = 5;
            "disks" = 300;
            "networks" = 3;
          };
          "format" = [
            " {cpu_percent}% | {cpu_frequency} GHz | {temp_c@CPUTIN}°C"
            " {memory_used} / {memory_total} GB ({memory_available} | {memory_percent2}%) | {swap_used} / {swap_total} GB ({swap_free} | {swap_percent}%)"
            "󰋊 {disk_used#T@/=.1} / {disk_total#T@/:.1} TB ({disk_percent@/}%) | {disk_read} / {disk_write} MB/s"
            "󰓢 {net_down@enp39s0} / {net_up@enp39s0} Mbps"
            "󰖡 {load_average1} | {load_average5} | {load_average15}"
            "󰥔 {uptime}"
          ];
        }
        {
          "type" = "volume";
          "format" = "{icon} {percentage}%";
          "max_volume" = 100;
          "icons" = {
            "volume_high" = "󰕾";
            "volume_medium" = "󰖀";
            "volume_low" = "󰕿";
            "muted" = "󰝟";
          };
        }
        {
          "type" = "notifications";
          "show_count" = true;
          "icons" = {
            "closed_none" = "󰍥";
            "closed_some" = "󱥂";
            "closed_dnd" = "󱅯";
            "open_none" = "󰍡";
            "open_some" = "󱥁";
            "open_dnd" = "󱅮";
          };
        }
        {
          "type" = "clock";
        }
      ];
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

      config.default_prog = { 'nu', '--config', '~/.config/nushell/wezterm-config.nu' }
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
        bottom = 0,
      }

      return config
    '';
  };

  home.packages = with pkgs; rofi-packages ++ [
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
