{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  profdata = ./merged.profdata;
  emacs' = pkgs.emacs-pgtk.overrideAttrs (old: {
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
    NIX_CFLAGS_COMPILE = toString (
      [
        "-O2"
        "-march=znver4"
        "-mtune=znver4"
        "-flto=full"
        "-fprofile-use=${profdata}"
      ]
      ++ old.NIX_CFLAGS_COMPILE or [ ]
    );

    patches = (old.patches or []) ++ [
      (pkgs.fetchpatch {
        url = "https://lists.gnu.org/archive/html/bug-gnu-emacs/2025-09/txtjcn89tkBPf.txt";
        sha256 = "sha256-cEZT9tq1BK/Ym80gmVF3g6LvJhy7fOkvL9cLPpI5FTg=";
      })
    ];
  });
in
{
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
    dockerfile-language-server
    # gcc
    # stdenv_mold
    gnumake
    config.programs.doom-emacs.finalDoomPackage
    emacs-lsp-booster
  ];

  systemd.user.startServices = true;

  programs.doom-emacs = {
    enable = true;
    emacs = emacs';
    doomDir = inputs.doom-config;
    doomLocalDir = "${config.xdg.dataHome}/doom";
    experimentalFetchTree = true;
    extraPackages =
      epkgs: with epkgs; [
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
