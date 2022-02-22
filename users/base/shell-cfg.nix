{ config, lib, pkgs, ... }:

{

  home.packages = with pkgs; [
    kitty
    nix-bash-completions
    bash-completion
    zenith
    lsof
    powertop
    pwgen-secure
    pwgen
    cachix
    gnupg
    exa
    bat
    fd
    procs
    tokei
    htop
    rlwrap
  ];

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    enableVteIntegration = true;
    history.share = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
      theme = "agnoster";
    };
    initExtra = ''
      alias ssh="kitty +kitten ssh"
    '';
  };

  programs.bash.enable = true;
  programs.bash.initExtra = ''
    export XDG_DATA_DIRS=${config.home.profileDirectory}/share:$XDG_DATA_DIRS
    . ${pkgs.bashCompletion}/share/bash-completion/bash_completion
    . ${pkgs.git}/share/git/contrib/completion/git-completion.bash
    for c in ${config.home.profileDirectory}/share/bash-completion/completions/*; do
      . $c
    done
    . $HOME/.bash_completion
  '';
}
