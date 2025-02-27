{ config, lib, pkgs, ... }:

let
  rustChannel = pkgs.rust-bin.stable.latest;
  rustpkgs = rustChannel.default.override {
    targets = [ "wasm32-unknown-unknown" ];
    extensions = [ "rust-src" "clippy-preview" "rust-analysis" ];
  };
in {
  home.packages = with pkgs; [
    (pkgs.lowPrio rustpkgs)
    pkgs.rust-analyzer
    cargo-audit
    cargo-web
    rustfmt
    gdb
    clang
  ];

  # home.file.".cargo/config.toml".text = ''
  #   [target.x86_64-unknown-linux-gnu]
  #   linker = "clang"
  #   rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"]
  # '';
}
