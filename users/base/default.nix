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
    ./xmonad.nix
  ];
}
