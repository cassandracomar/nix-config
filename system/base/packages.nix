{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    sops
    ssh-to-pgp
    wget
    vim
    htop
    ripgrep
    zsh
    git
    tmux
    xbacklight
    pamixer
    pavucontrol
    brightnessctl
    bc
    gnupg
    pinentry-curses
    paperkey
    virt-manager
    p7zip
    unrar
    unzip
    thunderbolt
    pciutils
    mesa-demos
    nix-zsh-completions
    (hwloc.override {
      x11Support = true;
      cairo = pkgs.cairo;
    })
    nix-output-monitor
    nh
    llama-cpp-vulkan
    (protonup-qt.overrideAttrs
      (old: {
        version = "2.15.1";

        src = appimageTools.extractType2 {
          inherit pname version;
          src = fetchurl {
            url = "https://github.com/DavidoTek/ProtonUp-Qt/releases/download/v${version}/ProtonUp-Qt-${version}-x86_64.AppImage";
            hash = "sha256-/Xjvsf+gkHpSV4RGJJS5tCk4+f18AZ8+rqO4+vg36ME=";
          };
        };
      }))
  ];

  programs.zsh.enable = true;
  # programs.java.enable = true;
  # programs.java.package = pkgs.openjdk17;
  # documentation.info.enable = false;

  services.pcscd.enable = true;
  services.udev.packages = with pkgs; [yubikey-personalization game-devices-udev-rules];
  services.fwupd.enable = true;
  services.autorandr.enable = true;

  programs.bash.completion.enable = true;

  programs.dconf.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  programs.steam = {
    enable = true;
    package = pkgs.steam.override {
      extraEnv = {
        MANGOHUD = true;
      };
    };

    extraPackages = with pkgs; [
      gamescope
      mangohud
    ];
    extraCompatPackages = let
      proton-ge-bin-11 = pkgs.proton-ge-bin.overrideAttrs (old: rec {
        version = "GE-Proton11-1";

        src = pkgs.fetchzip {
          url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
          hash = "sha256-I7SSvzQQ/NqdvwjpJ9IFFtAaTS+rgHUyXx0us1vIOnw=";
        };
      });
    in
      with pkgs; [
        proton-ge-bin
        proton-ge-bin-11
      ];

    gamescopeSession = {
      enable = true;
      args = [
        "-w 3840"
        "-W 3840"
        "-h 2160"
        "-H 2160"
        "-r 120"
        "--adaptive-sync"
        "--mangoapp"
        "--rt"
        "--prefer-vk-device 1002:73df"
        "--hdr-enabled"
        "--hdr-itm-enable"
        "--expose-wayland"
        "-e"
      ];
      env = {
        "DXVK_HDR" = "1";
      };
    };
    protontricks.enable = true;
  };
  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    package = pkgs.gamescope.overrideAttrs (_: {
      NIX_CFLAGS_COMPILE = ["-fno-fast-math"];
    });
  };

  hardware.steam-hardware.enable = true;
  hardware.uinput.enable = true;
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="268b", MODE:="0666", GROUP="users"
  '';

  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    loadModels = ["deepseek-r1:latest"];
    openFirewall = true;
  };
  # make sure amdgpu has initialized.
  systemd.services = {
    ollama = {
      wantedBy = lib.mkForce ["graphical.target"];
      after = lib.mkForce ["graphical.target" "network-online.target"];
      wants = lib.mkForce ["network-online.target"];
      environment = {
        GGML_VK_VISIBLE_DEVICES = "0";
      };
    };
    ollama-model-loader = {
      wantedBy = lib.mkForce ["ollama.service"];
      wants = ["network-online.target"];
    };
  };

  programs.fish = {
    enable = true;
    vendor = {
      config.enable = true;
      completions.enable = true;
      functions.enable = true;
    };
    generateCompletions = true;
  };
  documentation.man.cache.enable = true;
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
  };
}
