{
  config,
  pkgs,
  inputs,
  system,
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
    (oh-my-posh.overrideAttrs (old: rec {
      version = "29.28.0";
      src = pkgs.fetchFromGitHub {
        owner = "JanDeDobbeleer";
        repo = "oh-my-posh";
        tag = "v${version}";
        sha256 = "sha256-8V1Wu3wqakwSVNb/WPlxRy9KL33frb8nqWeorHuIuzI=";
      };
      vendorHash = "sha256-6DX/x9uWUbwXy9ccB6NIVRKsOc1nJXtctItONAI7zPQ=";
    }))
    (writeScriptBin "nixos-rebuild" (builtins.readFile ../../scripts/nixos-rebuild))
    (writeScriptBin "hm" (builtins.readFile ../../scripts/hm))
  ];

  home.shell.enableShellIntegration = true;

  programs.nushell = {
    enable = true;
    extraEnv = ''
      def --env get-env [name] { $env | get $name }
      def --env set-env [name, value] { load-env { $name: $value } }
      def --env unset-env [name] { hide-env $name }

      # set up fallback completions for commands carapace lacks
      $env.CARAPACE_BRIDGES = 'fish,bash,zsh,inshellisense'
      $env.config.render_right_prompt_on_last_line = false
      $env.config.history.max_size = 9999999
    '';
  };

  # interop configuration that ensures nushell is providing the right OSC codes for eat
  xdg.configFile."nushell/eat-config.nu".source = ./nushell/eat-config.nu;
  # the main config file to use within emacs' eat terminal emulator
  xdg.configFile."nushell/emacs-config.nu".source = ./nushell/emacs-config.nu;
  # the main config file to use from an interactive terminal
  xdg.configFile."nushell/wezterm-config.nu".source = ./nushell/wezterm-config.nu;
  # the base config that should be applied to both profiles
  xdg.configFile."nushell/default-config.nu".source = ./nushell/default-config.nu;
  # reworked prompt theme loading
  xdg.configFile."nushell/oh-my-posh.nu".source = ./nushell/oh-my-posh.nu;
  xdg.configFile."nushell/devious-diamonds.omp.yaml".source = ./nushell/devious-diamonds.omp.yaml;

  programs.fish = {
    enable = true;
    generateCompletions = true;
  };

  programs.carapace = {
    enable = true;
    # we want nix completions from fish so disable this and add it manually
    enableNushellIntegration = false;
    enableFishIntegration = false;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  services.gpg-agent = {
    enable = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableSshSupport = true;
    enableExtraSocket = true;
    enableScDaemon = true;
    pinentry.package = pkgs.pinentry-rofi;
  };

  programs.password-store.enable = false;
  services.pass-secret-service.enable = false;
  services.yubikey-agent.enable = false;

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
      get_completions() {
        typeset -U path cdpath fpath manpath

        for profile in ''${(z)NIX_PROFILES}; do
          fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
        done
        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

        plugins=(git sudo kubectl)

        HOME=/home/cassandra
        PATH="$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.krew/bin:$PATH";
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

  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  programs.nix-index = {
    enable = true;
    package = inputs.nix-index.packages.${system}.default;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };
}
