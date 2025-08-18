{ config, lib, pkgs, ... }:

{
  imports = [
    ./elixir.nix
    ./emacs.nix
    ./environment.nix
    ./games.nix
    ./haskell.nix
    ./kubernetes.nix
    ./packages.nix
    ./rust.nix
    ./shell-cfg.nix
    # ./xmonad.nix
  ];

  nix.settings = {
    accept-flake-config = true;
    extra-sandbox-paths = [ "/data/androidKeys" "/var/www/updater.ndra.io" "/bin/sh=${pkgs.bash}/bin/sh" ];
    trusted-substituters = [
      "https://cache.iog.io"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org/"
      "https://cache.iog.io"
    ];
  };
}
