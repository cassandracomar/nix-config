{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    rlaunch
    # (pkgs.hiPrio haskellPackages.stack)
    # haskell-language-server
    # haskellPackages.cabal-install
    # ghc
  ];
}
