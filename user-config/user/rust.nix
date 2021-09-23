{ ... }:
let
  moz_overlay = import (builtins.fetchTarball
    "https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz");
  nixpkgs = import <nixpkgs> { overlays = [ moz_overlay ]; };
  rustChannel = nixpkgs.rustChannelOf {
    date = "2021-04-16";
    channel = "nightly";
    # channel = "stable";
  };
  rustpkgs = rustChannel.rust.override {
    targets = [ "wasm32-unknown-unknown" ];
    extensions = [ "rust-src" "clippy-preview" ];
  };
  rustPlatform = nixpkgs.rustPlatform // {
    rustc = rustpkgs;
    cargo = rustpkgs;
  };

  rust-analyzer-pkg =
    (nixpkgs.rust-analyzer.override { rustPlatform = rustPlatform; });
in with nixpkgs;
mkShell {
  buildInputs = [
    openssl
    pkg-config
    llvmPackages.libclang
    clang
    nasm
    rustpkgs
    cmake
    zlib
    cargo-audit
    x11
    rustup
    cargo-web
    rust-analyzer-pkg
    rustfmt
  ];
  shellHook = ''
    export LIBCLANG_PATH="${pkgs.llvmPackages.libclang}/lib";
    rustup target add wasm32-unknown-unknown
    export PATH=${rust-analyzer-pkg}/bin:$HOME/.cargo/bin:$PATH
  '';
}
