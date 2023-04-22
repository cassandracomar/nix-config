# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, pkgs-master, system, ... }: {

  nixpkgs.hostPlatform = system;
  nix = {
    package = pkgs-master.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    settings = {
      auto-optimise-store = true;
      trusted-public-keys = [
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      ];
      substituters = [
        "https://cache.iog.io"
      ];
      accept-flake-config = true;
      extra-sandbox-paths = [ "/data/androidKeys" ];
    };
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 30d";
    };
  };

  system.autoUpgrade = {
    enable = true;
    flake = "path:/etc/nixos";
    flags = [ "--update-input" "nixpkgs" "--update-input" "nix-config" ];
    dates = "daily";
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  imports = [
    ./boot.nix
    ./cachix.nix
    ./docker.nix
    ./fonts.nix
    ./gnupg.nix
    ./networking.nix
    ./packages.nix
    ./power-management.nix
    ./sound.nix
    ./users.nix
    ./vpn.nix
    ./x11.nix
    ./android-updater.nix
  ];

  security.wrappers.hcitool = {
    source = "${pkgs.bluez}/bin/hcitool";
    owner = "root";
    group = "root";
    capabilities = "cap_net_raw,cap_net_admin+eip";
  };
  services.irqbalance.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
