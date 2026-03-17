{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  llama-cpp-vulkan = pkgs.llama-cpp-vulkan.overrideAttrs (final: prev: {
    version = "8298";
    src = pkgs.fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      rev = "3a5cb629b180a074e02056a40695528a2171254c";
      sha256 = "sha256-kjogc/NBMZWLaHU3jeIoQVNs4yjqWZIDcXaylkWfzGo=";
    };
    npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  });
in {
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
  ];

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
    package = pkgs.ollama-vulkan.overrideAttrs (old: {
      version = "0.17.7";
      src = pkgs.fetchFromGitHub {
        owner = "ollama";
        repo = "ollama";
        rev = "38908542184bffcf770ad90ced6d5aee6d50b8bf";
        sha256 = "sha256-aOdqefFikIg7MvvQTCopABSCdlshe4x/PKYrkXXQBBo=";
      };
    });
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
  documentation.man.generateCaches = true;
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
  };
}
