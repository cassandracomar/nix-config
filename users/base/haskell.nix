{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    haskellPackages.yeganesh
    (pkgs.hiPrio haskellPackages.stack)
    haskell-language-server
    haskellPackages.cabal-install
    ghc
  ];
}
