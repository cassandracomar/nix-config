{
  lib,
  pkgs,
  inputs,
  config,
  ...
}: let
  emacs' = pkgs.emacsWithDoom {
    doomDir = inputs.doom-config;
    doomLocalDir = "${config.xdg.dataHome}/doom";
    emacs = pkgs.emacs-pgtk;
    experimentalFetchTree = true;
    extraPackages = epkgs:
      with epkgs; [
        vterm
        sqlite3
        emacsql
        treesit-grammars.with-all-grammars
      ];
    extraBinPackages = with pkgs; [
      nixd
      gnumake
      sqlite
      pinentry-emacs
    ];
  };
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
  ];

  systemd.user.startServices = true;

  programs.emacs = {
    enable = true;
    package = emacs';
  };
  services.emacs = {
    enable = true;
    package = emacs';
    startWithUserSession = "graphical";
  };
  home.file.".tree-sitter".source = pkgs.runCommand "grammars" {} ''
    mkdir -p $out/bin
    ${lib.concatStringsSep "\n"
      (lib.mapAttrsToList (name: src: "name=${name}; ln -s ${src}/parser $out/bin/\${name#tree-sitter-}.so") pkgs.tree-sitter.builtGrammars)};
  '';
}
