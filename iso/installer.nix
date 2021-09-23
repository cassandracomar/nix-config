{ config, lib, options, pkgs, ... }:
with lib;

{

  nixpkgs.config.allowUnfree = true;
  boot.supportedFilesystems =
    [ "zfs" "f2fs" "ext4" "xfs" "cifs" "vfat" "ntfs" ];
  boot.zfs.enableUnstable = true;
  boot.kernelModules = [ "rtw89pci" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    acpi_call
    rtw89
  ];
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  hardware.wirelessRegulatoryDatabase = true;

  networking.networkmanager.enable = true;
  networking.wireless.enable = false;
  networking.hostId = "604df261";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "ter-232n";
    earlySetup = true;
    packages = with pkgs; [ terminus_font ];
  };

  time.timeZone = "America/New_York";

  environment.systemPackages = with pkgs; [
    wget
    vim
    htop
    ripgrep
    zsh
    git
    tmux
    gnupg
    pinentry-curses
    p7zip
    unrar
    unzip
  ];

  hardware.video.hidpi.enable = lib.mkDefault true;
  services.fwupd.enable = true;
  programs.zsh.enable = true;
  security.sudo.enable = true;
  security.sudo.extraConfig = ''
    %wheel	ALL=(ALL:ALL)	NOPASSWD:	ALL
  '';
  users.users.root = { shell = pkgs.zsh; };
  nix.trustedUsers = [ "root" ];
}
