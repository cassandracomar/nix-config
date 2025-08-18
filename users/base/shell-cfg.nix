{
  config,
  lib,
  pkgs,
  ...
}: {
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
    bat
    fd
    procs
    tokei
    htop
    rlwrap
    (vpn-slice.overrideAttrs (old: {
      version = "0.16.99-9ecb50d";
      src = fetchFromGitHub {
        owner = "dlenski";
        repo = old.pname;
        rev = "master";
        sha256 = "sha256-SEeIfA4/pJNmG1rq7nEXiDU+Drqa5kHrWFWK1b+21Kk=";
      };
      propagatedBuildInputs = old.propagatedBuildInputs ++ [pkgs.systemd pkgs.iproute2];
      patchPhase = ''
        substituteInPlace vpn_slice/linux.py --replace '/usr/bin/resolvectl' '${pkgs.systemd}/bin/resolvectl' --replace '/sbin/ip' '${pkgs.iproute2}/bin/ip';
      '';
    }))
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    history.share = true;
    oh-my-zsh = {
      enable = true;
      plugins = ["git" "sudo" "kubectl"];
      theme = "agnoster";
    };
    envExtra = ''
        get_completions
        () {
          typeset -U path cdpath fpath manpath

          for profile in ''${(z)NIX_PROFILES}; do
          fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
        done
        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

        plugins=(git sudo kubectl)

        HOME=/home/cassandra
        PATH="$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.doom-emacs.d/bin:$HOME/.emacs.d/bin:$HOME/.krew/bin:$PATH";
        ZSH_THEME="agnoster"
        source $ZSH/oh-my-zsh.sh
        compgen -A function -ac
      }
    '';
    initContent = ''
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
      vterm_printf() {
          if [ -n "$TMUX" ] && ([ "''${TERM%%-*}" = "tmux" ] || [ "''${TERM%%-*}" = "screen" ]); then
              # Tell tmux to pass the escape sequences through
              printf "\ePtmux;\e\e]%s\007\e\\" "$1"
          elif [ "''${TERM%%-*}" = "screen" ]; then
              # GNU screen (screen, screen-256color, screen-256color-bce)
              printf "\eP\e]%s\007\e\\" "$1"
          else
              printf "\e]%s\e\\" "$1"
          fi
      }
      vterm_prompt_end() {
          vterm_printf "51;A$(whoami)@$(hostname):$(pwd)"
      }
      setopt PROMPT_SUBST
      PROMPT=$PROMPT'%{$(vterm_prompt_end)%}'
    '';
  };

  programs.bash.enable = true;
  programs.bash.completion.enable = true;
  programs.bash.initExtra = ''
    export XDG_DATA_DIRS=${config.home.profileDirectory}/share:$XDG_DATA_DIRS
    . ${pkgs.bash-completion}/share/bash-completion/bash_completion
    . ${pkgs.git}/share/git/contrib/completion/git-completion.bash
    for c in ${config.home.profileDirectory}/share/bash-completion/completions/*; do
      . $c
    done
  '';

  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
