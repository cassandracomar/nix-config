{pkgs, ...}: {
  imports = [
    ./emacs.nix
    ./environment.nix
    ./games.nix
    ./haskell.nix
    ./kubernetes.nix
    ./packages.nix
    # ./rust.nix
    ./shell-cfg.nix
    ./pinnacle.nix
    # ./xmonad.nix
  ];

  home.packages = with pkgs; [rustc cargo];
}
