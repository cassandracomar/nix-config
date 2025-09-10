{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # haskell.packages.ghc810.yeganesh
    # (pkgs.hiPrio haskellPackages.stack)
    # haskell-language-server
    # haskellPackages.cabal-install
    # ghc
  ];
}
