# let
#   moz_overlay = import (builtins.fetchTarball
#     "https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz");
#   nixpkgs = import <nixpkgs> { overlays = [ moz_overlay ]; };
#   shells = [
#     #./rust.nix
#     ./terraform.nix
#     ./kops.nix
#   ];
# in rec {
#   importAll = builtins.map (s: import s { inherit nixpkgs; }) shells;
#   mkShells = nixpkgs.mkShell { inputsFrom = importAll; };
# }.mkShells

{ }
