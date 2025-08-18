{
  lib,
  pkgs,
  host,
  ...
}: let
  git_config_by_host = {
    rnwld-ccomar1 = {
      userName = "Cassandra Comar";
      userEmail = "ccomar@drwholdings.com";
      # signing = {
      #   key = "0xF431E5E70CAB3E2E";
      #   signByDefault = true;
      # };
      github.user = "cassandracomar";
      "git.drwholdings.com" = {
        user = "ccomar";
      };
    };
  };
  git_config = lib.getAttr host git_config_by_host;

  complete_alias = pkgs.stdenv.mkDerivation {
    name = "complete_alias";
    version = "1.18.0";
    src = pkgs.fetchFromGitHub {
      owner = "cykerway";
      repo = "complete-alias";
      rev = "4fcd018faa9413e60ee4ec9f48ebeac933c8c372";
      sha256 = "sha256-fZisrhdu049rCQ5Q90sFWFo8GS/PRgS29B1eG8dqlaI=";
    };
    buildInputs = [pkgs.bash-completion];
    installPhase = ''
      install -Dm444 -t $out/share/bash-completion/completions complete_alias
    '';
  };

  kubernetes_aliases = pkgs.writeTextFile {
    name = "kubernetes_aliases";
    destination = "/share/bash-completion/completions/kubernetes_aliases";
    text = ''
      source ${complete_alias}/share/bash-completion/completions/complete_alias
    '';
  };
in {
  imports = [./base];

  home.username = "ccomar";
  home.homeDirectory = "/home/ccomar";
  home.packages = with pkgs; [
    cachix
    gitAndTools.delta
    git-crypt
    complete_alias
    kubernetes_aliases
    iosevkaCustom
    inconsolata
    inconsolata-lgc
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    dejavu_fonts
    powerline-fonts
    corefonts
    symbola
    liberation_ttf
    fira-code
    fira-code-symbols
    # mplus-outline-fonts
    # dina-font
    proggyfonts
    arphic-ukai
    arphic-uming
    font-awesome
    noto-fonts-extra
    source-han-sans
    wqy_microhei
    wqy_zenhei

    # packages normally installed to system
    sops
    ssh-to-pgp
    wget
    vim
    htop
    ripgrep
    zsh
    git
    tmux
    xorg.xbacklight
    pamixer
    pavucontrol
    brightnessctl
    bc
    gnupg
    # pinentry-curses
    pinentry-gnome
    paperkey
    virt-manager
    pulseeffects-legacy
    p7zip
    unrar
    unzip
    thunderbolt
    pciutils
    glxinfo
    grub2_full
    nix-zsh-completions
    yubikey-personalization
    (hwloc.override {
      x11Support = true;
      libX11 = pkgs.xorg.libX11;
      cairo = pkgs.cairo;
    })
  ];
  home.sessionVariables.GITHUB_USER = git_config.github.user;

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableExtraSocket = true;
    pinentryFlavor = "gnome3";
  };
  programs.git = {
    inherit (git_config) userName userEmail;
    enable = true;
    delta.enable = true;
    extraConfig = {
      pull.rebase = false;
      inherit (git_config) github;
    };
  };

  programs.firefox = {
    enable = true;
    package = pkgs.firefox.override {
      extraPolicies = {DisableAppUpdate = true;};
    };
    profiles = {
      "yg8ij66s.default" = {
        isDefault = true;
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          reddit-enhancement-suite
          # https-everywhere
          umatrix
          tridactyl
          multi-account-containers
        ];
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

          #sidebar-box #sidebar-header {
            display: none;
          }
        '';
      };
    };
  };

  services.autorandr.enable = true;

  home.stateVersion = "23.05";
}
