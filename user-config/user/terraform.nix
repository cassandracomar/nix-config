{ ... }:
let pkgs = import <nixpkgs> { };
in with pkgs; mkShell { buildInputs = [ terraform_0_14 terragrunt ]; }
