{
  pkgs,
  ...
}: {
  imports = [
    ./emacs.nix
    ./environment.nix
    ./games.nix
    ./haskell.nix
    ./kubernetes.nix
    ./packages.nix
    ./rust.nix
    ./shell-cfg.nix
    ./pinnacle.nix
    # ./xmonad.nix
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    accept-flake-config = true;
    trusted-substituters = [
      "https://cache.iog.io"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org/"
      "https://cache.iog.io"
    ];
  };
}
