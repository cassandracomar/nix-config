{
  lib,
  pkgs,
  inputs,
  config,
  ...
}: let
  profdata = ./merged.profdata;
  emacs' = pkgs.emacs-igc-pgtk.overrideAttrs (old: {
    stdenv = pkgs.llvmPackages.stdenv;
    preConfigure = ''
      export CC=${pkgs.llvmPackages.clang}/bin/clang
      export CXX=${pkgs.llvmPackages.clang}/bin/clang++
      export AR=${pkgs.llvm}/bin/llvm-ar
      export NM=${pkgs.llvm}/bin/llvm-nm
      export LD=${pkgs.lld}/bin/ld.lld
      export RANLIB=${pkgs.llvm}/bin/llvm-ranlib
    '';

    # Extra compiler flags (Clang-flavored)
    NIX_CFLAGS_COMPILE = toString ([
        "-O2"
        "-march=znver4"
        "-mtune=znver4"
        "-flto=thin"
        # "-fprofile-generate"
        "-fprofile-use=${profdata}"
      ]
      ++ old.NIX_CFLAGS_COMPILE or []);
  });
in {
  home.packages = with pkgs; [
    sqlite
    direnv
    p7zip
    unrar
    unzip
    nixfmt
    alejandra
    nixd
    ripgrep
    pandoc
    nodePackages.bash-language-server
    yaml-language-server
    nodePackages.dockerfile-language-server-nodejs
    # gcc
    # stdenv_mold
    gnumake
    config.programs.doom-emacs.finalDoomPackage
  ];

  systemd.user.startServices = true;

  programs.doom-emacs = {
    enable = true;
    emacs = emacs';
    doomDir = inputs.doom-config;
    doomLocalDir = "${config.xdg.dataHome}/doom";
    experimentalFetchTree = true;
    extraPackages = epkgs:
      with epkgs; [
        vterm
        sqlite3
        emacsql
      ];
    extraBinPackages = with pkgs; [
      nixd
      gnumake
      sqlite
      pinentry-emacs
      emacs-lsp-booster
    ];
  };
  services.emacs = {
    enable = true;
    startWithUserSession = "graphical";
  };
}
