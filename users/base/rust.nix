{ config, lib, pkgs, pkgs-master, ... }:

let
  rustChannel = pkgs.rust-bin.stable.latest;
  rustpkgs = rustChannel.default.override {
    targets = [ "wasm32-unknown-unknown" ];
    extensions = [ "rust-src" "clippy-preview" "rust-analysis" ];
  };
in {
  home.packages = with pkgs; [
    (pkgs.lowPrio rustpkgs)
    pkgs-master.rust-analyzer
    cargo-audit
    cargo-web
    rustfmt
    gdb
  ];
}
