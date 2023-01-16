{ config, lib, pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
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
    glxinfo
    grub2_full
    nix-zsh-completions
    (hwloc.override {
      x11Support = true;
      libX11 = pkgs.xorg.libX11;
      cairo = pkgs.cairo;
    })
  ];

  programs.zsh.enable = true;
  programs.java.enable = true;

  services.pcscd.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];
  services.fwupd.enable = false;
  services.autorandr.enable = true;

  programs.bash.enableCompletion = true;

  programs.dconf.enable = true;

  services.transmission = { enable = true; };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  programs.adb.enable = true;

  programs.steam.enable = true;
  programs.gamemode.enable = true;
  hardware.steam-hardware.enable = true;

  # services.actualbudget.enable = true;

}
