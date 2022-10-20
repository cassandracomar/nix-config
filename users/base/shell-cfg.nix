{ config, lib, pkgs, ... }:

{

  home.packages = with pkgs; [
    kitty
    nix-bash-completions
    nix-zsh-completions
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
      plugins = [ "git" "sudo" "kubectl" ];
      theme = "agnoster";
    };
    initExtra = ''
      alias ls="ls -l --color=always"
      alias ssh="kitty +kitten ssh"
      alias vim="emacsclient"
      alias s='emacsclient -n -e \(magit-status\)'
      alias cictl="kubectl --context=cassandracomar@ci.k8s.ditto.live"
      alias devctl="kubectl --context=cassandracomar@dev.k8s.ditto.live"
      alias stgctl="kubectl --context=cassandracomar@stg.k8s.ditto.live"
      alias prodctl="kubectl --context=cassandracomar@prod.k8s.ditto.live"
      alias particleprodctl="kubectl --context=cassandracomar@particle-prod.k8s.ditto.live"
      alias particlestgctl="kubectl --context=cassandracomar@particle-stg.k8s.ditto.live"
    '';
  };

  programs.bash.enable = true;
  programs.bash.initExtra = ''
    export XDG_DATA_DIRS=${config.home.profileDirectory}/share:$XDG_DATA_DIRS
    . ${pkgs.bash-completion}/share/bash-completion/bash_completion
    . ${pkgs.git}/share/git/contrib/completion/git-completion.bash
    for c in ${config.home.profileDirectory}/share/bash-completion/completions/*; do
      . $c
    done
    . $HOME/.bash_completion
  '';

  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
