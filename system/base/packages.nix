{
  config,
  lib,
  pkgs,
  inputs,
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
    xorg.xbacklight
    pamixer
    pavucontrol
    brightnessctl
    bc
    gnupg
    pinentry-curses
    paperkey
    virt-manager
    pulseeffects-legacy
    p7zip
    unrar
    unzip
    thunderbolt
    pciutils
    mesa-demos
    nix-zsh-completions
    (hwloc.override {
      x11Support = true;
      libX11 = pkgs.xorg.libX11;
      cairo = pkgs.cairo;
    })
    nix-output-monitor
  ];
  programs.command-not-found = {
    enable = true;
    dbPath = "${inputs.nixpkgs}/programs.sqlite";
  };

  programs.zsh.enable = true;
  # programs.java.enable = true;
  # programs.java.package = pkgs.openjdk17;
  # documentation.info.enable = false;

  services.pcscd.enable = true;
  services.udev.packages = [pkgs.yubikey-personalization];
  services.fwupd.enable = true;
  services.autorandr.enable = true;

  programs.bash.completion.enable = true;

  programs.dconf.enable = true;

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
  };

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
    extraCompatPackages = with pkgs; [
      proton-ge-bin
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
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="268b", MODE:="0666", GROUP="users"
  '';

  services.ollama = {
    enable = true;
    loadModels = ["deepseek-r1:latest"];
  };
}
