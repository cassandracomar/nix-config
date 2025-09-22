{
  config,
  lib,
  pkgs,
  nixpkgs,
  ...
}: let
  lib' = pkgs.callPackage "${nixpkgs}/pkgs/development/beam-modules/lib.nix" {};
  elixir-local = lib'.callElixir "${nixpkgs}/pkgs/development/interpreters/elixir/1.12.nix" {
    erlang = pkgs.erlangR24;
  };
  hex-local = pkgs.beamPackages.hex.override {
    elixir = elixir-local;
  };
  rebar-local = pkgs.beamPackages.rebar.override {
    erlang = pkgs.erlangR24;
  };
  rebar3-local = pkgs.beamPackages.rebar3.overrideAttrs (old: {
    erlang = pkgs.erlangR24;
  });
  fetchMixDeps = pkgs.callPackage "${nixpkgs}/pkgs/development/beam-modules/fetch-mix-deps.nix" {
    hex = hex-local;
    rebar = rebar-local;
    elixir = elixir-local;
  };
  mixRelease = pkgs.callPackage "${nixpkgs}/pkgs/development/beam-modules/mix-release.nix" {
    inherit fetchMixDeps;
    hex = hex-local;
    rebar = rebar-local;
    erlang = pkgs.erlangR24;
    elixir = elixir-local;
  };
  elixir-ls-local = pkgs.callPackage "${nixpkgs}/pkgs/development/beam-modules/elixir-ls/" {
    inherit (pkgs) lib fetchFromGitHub;
    inherit mixRelease fetchMixDeps;
    elixir = elixir-local;
  };
in {
  home.packages = with pkgs; [
    elixir-local
    elixir-ls-local
    nodejs-16_x
    postgresql_13
    erlangR24
    hex-local
    rebar3-local
  ];
}
