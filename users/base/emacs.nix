{
  lib,
  pkgs,
  inputs,
  ...
}: {
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
    doomDir = inputs.doom-config;
    emacs = pkgs.emacs-pgtk;
    # experimentalFetchTree = true;
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
    provideEmacs = true;
  };
  # programs.emacs = {
  #   enable = true;
  #   package = pkgs.emacs-pgtk;
  #   extraPackages = epkgs:
  #     with pkgs; [
  #       lilypond
  #       timidity
  #       sqlite
  #       # gcc
  #       gnumake
  #       epkgs.vterm
  #       epkgs.sqlite3
  #       epkgs.emacsql
  #       pinentry-emacs
  #       nixd
  #       epkgs.treesit-grammars.with-all-grammars
  #     ];
  # };
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
