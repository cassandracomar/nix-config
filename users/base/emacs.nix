{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    sqlite
    direnv
    p7zip
    unrar
    unzip
    nixfmt
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
    package = pkgs.emacsPgtk;
    extraPackages = epkgs:
      with pkgs; [
        lilypond
        timidity
        sqlite
        stdenv_mold
        # gcc
        gnumake
        epkgs.vterm
        epkgs.sqlite3
        epkgs.emacsql
        epkgs.emacsql-sqlite3
        rnix-lsp
      ];
  };
  services.emacs.enable = true;
  home.file.".tree-sitter".source = (pkgs.runCommand "grammars" { } ''
    mkdir -p $out/bin
    ${lib.concatStringsSep "\n"
      (lib.mapAttrsToList (name: src: "name=${name}; ln -s ${src}/parser $out/bin/\${name#tree-sitter-}.so") pkgs.tree-sitter.builtGrammars)};
  '');
}
