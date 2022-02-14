{ config, lib, pkgs, username, ... }:

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
    export XDG_DATA_DIRS=$HOME/.nix-profile/share:$XDG_DATA_DIRS
    source $HOME/.nix-profile/etc/profile.d/bash_completion.sh
    source ${pkgs.bashCompletion}/share/bash-completion/bash_completion
    source ${pkgs.nix-bash-completions}/share/bash-completion/completions/*
    source ${pkgs.git}/share/git/contrib/completion/git-completion.bash
    source $HOME/.nix-profile/share/bash-completion/completions/*
    source $HOME/.bash_completion
  '';
}
