{ ... }:
let pkgs = import <nixpkgs> { };
in with pkgs;
rec {
  kops_1_18 = pkgs.mkKops {
    version = "v1.18.2";
    sha256 = "17na83j6sfhk69w9ssvicc0xd1904z952ad3zzbpha50lcy6nlhp";
  };
  kops = mkShell { buildInputs = [ kops_1_18 ]; };
}.kops
