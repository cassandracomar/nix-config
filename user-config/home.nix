{ lib, config, pkgs, options, ... }:
let
  nixpkgs = (import <nixpkgs> {
    overlays = [
      (import (builtins.fetchTarball
        "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
    ];
  });
  nixos = import <nixos-unstable> {
    overlays = [
      (import (builtins.fetchGit {
        url = "https://github.com/nix-community/emacs-overlay.git";
        ref = "master";
      }))
    ];
  };
  nixpkgs-master = (import (/home/cassandra/src/github.com/nixos/nixpkgs) { });
  rustChannel = nixpkgs.rust-bin.nightly."2021-06-23";
  rustpkgs = rustChannel.default.override {
    targets = [ "wasm32-unknown-unknown" ];
    extensions = [ "rust-src" "clippy-preview" "rust-analysis" ];
  };
  fetchCargoTarball =
    nixpkgs.rustPlatform.fetchCargoTarball.override { cargo = rustpkgs; };
  rustPlatform = {
    rust = {
      rustc = rustpkgs;
      cargo = rustpkgs;
    };
    fetchCargoTarball = fetchCargoTarball;
    buildRustPackage = nixpkgs.rustPlatform.buildRustPackage.override {
      rustc = rustpkgs;
      fetchCargoTarball = fetchCargoTarball;
    };
    rustcSrc = rustChannel.rust-src;
    rustLibSrc = "${rustChannel.rust-src}/library";
  };
  rust-analyzer-pkg = nixpkgs-master.rust-analyzer.override {
    rustPlatform = rustPlatform;
    rust-analyzer-unwrapped = nixpkgs-master.rust-analyzer-unwrapped.override {
      rustPlatform = rustPlatform;
    };
  };
in {
  nixpkgs.overlays = [
    (import (builtins.fetchGit {
      url = "https://github.com/nix-community/emacs-overlay.git";
      ref = "master";
    }))
    (import (builtins.fetchTarball
      "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
    (self: super: {
      discord = super.discord.overrideAttrs (_: {
        src = builtins.fetchTarball
          "https://discord.com/api/download?platform=linux&format=tar.gz";
      });
    })
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cassandra";
  home.homeDirectory = "/home/cassandra";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";

  home.packages = with nixpkgs;
    with pkgs; [
      haskellPackages.yeganesh
      (pkgs.hiPrio haskellPackages.stack)
      # haskell-language-server
      haskellPackages.cabal-install
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
      xournalpp
      discord
      pinta
      bind
      pwgen-secure
      pwgen
      libreoffice
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
      wineWowPackages.full
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
      (nixpkgs.lowPrio rustpkgs)
      cargo-audit
      cargo-web
      rust-analyzer-pkg
      rustfmt
      dbus
      nixpkgs-master.terraform
      gdb
      nyxt
      xclip
      sbcl
      buildkit
      bintools.bintools
      pkg-config
      lilypond
      nixpkgs-master.skype
      reaper
      tailscale
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
    "$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.doom-emacs.d/bin:$PATH";
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
      cbatticon &
    '';
  };

  programs.firefox = {
    enable = true;
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
        "change-background" = "~/.files/setBackground.sh";
      };
    };
  };

  programs.emacs = {
    enable = true;
    package = nixos.emacsGcc;
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
    nix-direnv = {
      enable = true;
      enableFlakes = true;
    };
  };

  programs.git = {
    enable = true;
    delta.enable = true;
    userName = "Cassandra Comar";
    userEmail = "cass@ndra.io";
    signing.key = "0x7740839F808C0207";
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
}
