{
  lib,
  pkgs,
  inputs,
  config,
  ...
}: let
  emacs' = pkgs.emacsWithDoom {
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

  programs.doom-emacs = {
    enable = true;
    emacs = pkgs.emacs-pgtk;
    doomDir = inputs.doom-config;
    doomLocalDir = "${config.xdg.dataHome}/doom";
    experimentalFetchTree = true;
    extraPackages = epkgs:
      with epkgs; [
        vterm
        sqlite3
        emacsql
        treesit-grammars.with-all-grammars
        (lsp-mode.overrideAttrs (old: {
          env = {
            LSP_USE_PLISTS = "true";
          };
        }))
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
  home.file.".tree-sitter".source = pkgs.runCommand "grammars" {} ''
    mkdir -p $out/bin
    ${lib.concatStringsSep "\n"
      (lib.mapAttrsToList (name: src: "name=${name}; ln -s ${src}/parser $out/bin/\${name#tree-sitter-}.so") pkgs.tree-sitter.builtGrammars)};
  '';
}
