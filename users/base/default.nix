{pkgs, ...}: {
  imports = [
    ./emacs.nix
    ./environment.nix
    ./games.nix
    ./haskell.nix
    ./kubernetes.nix
    ./mail.nix
    ./packages.nix
    # ./rust.nix
    ./shell-cfg.nix
    ./pinnacle.nix
    # ./xmonad.nix
    ./vpn.nix
  ];

  home.packages = with pkgs; [rustc cargo];
}
