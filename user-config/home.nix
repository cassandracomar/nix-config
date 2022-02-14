{ pkgs, pkgs-master, ... }:
let
  rustChannel = pkgs.rust-bin.stable.latest;
  rustpkgs = rustChannel.default.override {
    targets = [ "wasm32-unknown-unknown" ];
    extensions = [ "rust-src" "clippy-preview" "rust-analysis" ];
  };
  complete_alias = pkgs.stdenv.mkDerivation {
    name = "complete_alias";
    version = "1.18.0";
    src = pkgs.fetchFromGitHub {
      owner = "cykerway";
      repo = "complete-alias";
      rev = "4fcd018faa9413e60ee4ec9f48ebeac933c8c372";
      sha256 = "sha256-fZisrhdu049rCQ5Q90sFWFo8GS/PRgS29B1eG8dqlaI=";
    };
    buildInputs = [ pkgs.bash-completion ];
    installPhase = ''
      install -Dm444 -t $out/share/bash-completion/completions complete_alias
    '';
  };
  kubernetes_aliases = pkgs.writeTextFile {
    name = "kubernetes_aliases";
    destination = "/share/bash-completion/completions/kubernetes_aliases";
    text = ''
      source ${complete_alias}/share/bash-completion/completions/complete_alias

      alias devctl="kubectl --context=cassandracomar@dev.k8s.ditto.live"
      complete -F _complete_alias devctl

      alias stgctl="kubectl --context=cassandracomar@stg.k8s.ditto.live"
      complete -F _complete_alias stgctl

      alias prodctl="kubectl --context=cassandra@prod.k8s.ditto.live"
      complete -F _complete_alias prodctl

      alias particleprodctl="kubectl --context=cassandracomar@particle-prod.k8s.ditto.live"
      complete -F _complete_alias particleprodctl

      alias particlestgctl="kubectl --context=cassandracomar@particle-stg.k8s.ditto.live"
      complete -F _complete_alias particlestgctl
    '';
  };
in {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    haskell.packages.ghc902.yeganesh
    (pkgs.hiPrio haskell.packages.ghc902.stack)
    haskell-language-server
    haskell.packages.ghc902.cabal-install
    haskell.packages.ghc902.ghc
    dmenu
    dzen2
    conky
    trayer
    sakura
    cbatticon
    #dunst
    gnome3.adwaita-icon-theme
    qogir-theme
    powertop
    sqlite
    slack
    zoom-us
    nixfmt
    cmake
    gnumake
    signal-desktop
    p7zip
    unrar
    unzip
    monero
    monero-gui
    gitAndTools.delta
    keepassxc
    google-chrome
    scrot
    kubectl
    krew
    kind
    direnv
    kubernetes-helm
    minikube
    docker-machine-kvm2
    pandoc
    ispell
    gradle
    pass
    docker-credential-helpers
    yaml-language-server
    aws-iam-authenticator
    yq
    eksctl
    lsof
    docker-credential-helpers
    pass
    pandoc
    skaffold
    discord
    pinta
    bind
    pwgen-secure
    pwgen
    cachix
    gnome3.gnome-calculator
    openssl
    kitty
    gptfdisk
    lxappearance
    usbutils
    xorg.xev
    brightnessctl
    stack
    vlc
    nodePackages.bash-language-server
    nodePackages.dockerfile-language-server-nodejs
    ripgrep
    gnupg
    exa
    bat
    fd
    procs
    #dust
    tokei
    htop
    rlwrap
    wineWowPackages.stable
    winetricks
    lutris
    vulkan-tools
    virt-viewer
    spotify
    curlFull
    istioctl
    wasm-pack
    awscli2
    git-crypt
    vault
    nix-bash-completions
    bash-completion
    chessx
    stockfish
    rclone
    syncthing
    openssl
    (pkgs.lowPrio rustpkgs)
    cargo-audit
    cargo-web
    pkgs-master.rust-analyzer
    rustfmt
    dbus
    terraform
    gdb
    nyxt
    xclip
    sbcl
    buildkit
    bintools.bintools
    pkg-config
    lilypond
    skype
    reaper
    tailscale
    zenith
    evtest
    audacity
    pkgs-master.ocenaudio
    rustpkgs
    retroarchFull
    monero-gui
    bisq-desktop
    complete_alias
    kubernetes_aliases
    jsonnet-bundler
    tanka
  ];

  systemd.user.startServices = true;
  home.sessionVariables._JAVA_AWT_WM_NONREPARENTING = "1";
  home.sessionVariables.MOZ_ACCELERATED = "1";
  home.sessionVariables.MOZ_WEBRENDER = "1";
  home.sessionVariables.EDITOR = "emacsclient -t";
  home.sessionVariables.VISUAL = "emacsclient -c";
  home.sessionVariables.ALTERNATE = "vim";
  home.sessionVariables.NIX_PATH = "$HOME/.config/nixpkgs:$NIX_PATH";
  home.sessionVariables.XDG_DATA_DIRS =
    "$HOME/.nix-profile/share:$XDG_DATA_DIRS";
  home.sessionVariables.PATH =
    "$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.doom-emacs.d/bin:$HOME/.krew/bin:$PATH";
  home.sessionVariables.GDK_SCALE = "2";
  home.sessionVariables.GDK_DPI_SCALE = "0.5";

  xresources.extraConfig = ''
    Xft.dpi: 200
    Xft.autohint: 0
    Xft.lcdfilter: lcddefault
    Xft.hintstyle: hintfull
    Xft.hinting: 1
    Xft.antialias: 1
    Xft.rgba: rgb
  '';

  xsession = {
    enable = true;
    windowManager = {
      xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };
    };
    pointerCursor.package = pkgs.vanilla-dmz;
    pointerCursor.name = "Vanilla-DMZ";
    initExtra = ''
      # ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource NVIDIA-G0 "Unknown AMD Radeon GPU @ pci:0000:05:00.0"
      ${pkgs.feh}/bin/feh --bg-fill /home/cassandra/wallpapers/haskell-wallpaper.png
      cbatticon &
    '';
    # profileExtra = ''
    #   ${pkgs.feh}/bin/feh --bg-fill /home/cassandra/wallpapers/haskell-wallpaper.png
    # '';
  };

  programs.firefox = {
    enable = true;
    package = pkgs.latest.firefox-nightly-bin;
    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      reddit-enhancement-suite
      https-everywhere
      umatrix
      tridactyl
      multi-account-containers
    ];
    profiles = {
      "yg8ij66s.default" = {
        isDefault = true;
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = "true";
        };
        userChrome = ''
          #main-window[tabsintitlebar="true"]:not([extradragspace="true"]) #TabsToolbar > .toolbar-items {
            opacity: 0;
            pointer-events: none;
          }
          #main-window:not([tabsintitlebar="true"]) #TabsToolbar {
            visibility: collapse !important;
          }

          #sidebar-box[sidebarcommand="treestyletab_piro_sakura_ne_jp-sidebar-action"] #sidebar-header {
            display: none;
          }
        '';
      };
    };
  };

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

  programs.feh.enable = true;
  programs.jq.enable = true;
  programs.autorandr = {
    enable = true;
    hooks = {
      postswitch = {
        "notify-xmonad" = "xmonad --restart";
        "change-background" =
          "${pkgs.feh}/bin/feh --bg-fill /home/cassandra/wallpapers/haskell-wallpaper.png";
        "reset-dpms" = ''
          #! ${pkgs.bash}/bin/bash
          if [[ $(${pkgs.autorandr}/bin/autorandr --detected | grep undocked) == "undocked" ]]; then
            ${pkgs.xorg.xset}/bin/xset s on +dpms
          else
            ${pkgs.xorg.xset}/bin/xset s off -dpms
          fi
        '';
      };
    };
  };

  programs.emacs = {
    enable = true;
    package = pkgs.emacsPgtkGcc;
    extraPackages = epkgs:
      with pkgs; [
        lilypond
        timidity
        sqlite
        epkgs.vterm
        epkgs.emacsql-sqlite3
      ];
  };
  services.emacs.enable = true;

  services.dunst = {
    enable = true;
    iconTheme.name = "Adwaita";
    iconTheme.package = pkgs.gnome3.adwaita-icon-theme;
    settings = {
      global = {
        geometry = "600x3-0+40";
        markup = "full";
      };
    };
  };

  services.lorri.enable = true;
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv = { enable = true; };
  };

  programs.git = {
    enable = true;
    delta.enable = true;
    userName = "Cassandra Comar";
    userEmail = "cassandra@ditto.live";
    signing.key = "0xF431E5E70CAB3E2E";
    signing.signByDefault = true;
    extraConfig = {
      pull.rebase = false;
      github.user = "cassandracomar";
    };
  };

  programs.obs-studio = { enable = true; };

  programs.zathura = { enable = true; };

  programs.bash.enable = true;
  programs.bash.initExtra = ''
    export GITHUB_USER=cassandracomar
    export XDG_DATA_DIRS=$HOME/.nix-profile/share:$XDG_DATA_DIRS
    source $HOME/.nix-profile/etc/profile.d/bash_completion.sh
    source ${pkgs.bashCompletion}/share/bash-completion/bash_completion
    source ${pkgs.nix-bash-completions}/share/bash-completion/completions/*
    source ${pkgs.git}/share/git/contrib/completion/git-completion.bash
    source $HOME/.nix-profile/share/bash-completion/completions/*
    source $HOME/.bash_completion
  '';

  services = {
    syncthing = {
      enable = true;
      # user = "therivercass";
      # dataDir = "/home/cassandra/drive";
      # configDir = "/home/cassandra/.config/";
    };
  };
  # programs.steam.enable = true;
}
