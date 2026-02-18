{
  pkgs,
  config,
  lib,
  ...
}: let
  git_config = {
    userName = "Cassandra Comar";
    userEmail = "ccomar@drwholdings.com";
    github = {
      user = "cassandracomar";
      "git.drwholdings.com/api/v3".user = "ccomar";
    };
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
  profdata = ./base/merged-intel.profdata;
  emacs' = pkgs.emacs-igc-pgtk.overrideAttrs (old: {
    stdenv = pkgs.llvmPackages.stdenv;
    preConfigure = ''
      export CC=${pkgs.llvmPackages.clang}/bin/clang
      export CXX=${pkgs.llvmPackages.clang}/bin/clang++
      export AR=${pkgs.llvm}/bin/llvm-ar
      export NM=${pkgs.llvm}/bin/llvm-nm
      export LD=${pkgs.lld}/bin/ld.lld
      export RANLIB=${pkgs.llvm}/bin/llvm-ranlib
    '';

    # Extra compiler flags (Clang-flavored)
    NIX_CFLAGS_COMPILE = toString (
      [
        "-O3"
        "-march=meteorlake"
        "-mtune=meteorlake"
        "-flto=full"
        # "-fcs-profile-generate"
        "-fprofile-use=${profdata}"
      ]
      ++ old.NIX_CFLAGS_COMPILE or []
    );
  });
in {
  imports = [./base];

  services.home-manager.autoExpire = {
    enable = true;
    frequency = "daily";
    timestamp = "-7 days";
  };

  systemd.user.services.nix-gc = {
    Unit = {
      Description = "Nix Garbage Collector";
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nix-gc" "exec ${pkgs.lix}/bin/nix store gc --verbose --debug";
    };
  };
  systemd.user.timers.nix-gc = {
    Unit = {
      Description = "Nix Garbage Collector";
    };
    Timer = {
      OnCalendar = "daily";
      RandomizedDelaySec = 3600;
      Persistent = true;
      Unit = "nix-gc.service";
    };
    Install = {
      WantedBy = ["timers.target"];
    };
  };

  targets.genericLinux = {
    enable = true;
    nixGL = {
      prime = {
        installScript = "nvidia";
      };
    };
    gpu = {
      enable = true;
      nvidia = {
        enable = true;
        version = "590.48.01";
        sha256 = "sha256-ueL4BpN4FDHMh/TNKRCeEz3Oy1ClDWto1LO/LWlr1ok=";
      };
    };
  };
  home.sessionVariables = {
    GITHUB_USER = git_config.github.user;
    GSETTINGS_SCHEMA_DIR = "/usr/share/glib-2.0/schemas";
    NH_FLAKE = "${config.home.homeDirectory}/src/github.com/cassandracomar/nix-config";
  };
  programs.doom-emacs.emacs = emacs';
  wayland.windowManager.pinnacle = {
    systemd.useService = lib.mkForce true;
    config = {
      nixGL.enable = false;
      xdg-portals.enable = true;
    };
  };
  xdg.systemDirs.data = ["/usr/share/ubuntu" "/usr/share/gnome" "/usr/local/share" "/usr/share"];

  services.wpaperd.package = pkgs.wpaperd;
  services.clipcat.package = pkgs.clipcat;
  programs.wezterm.package = pkgs.wezterm;
  programs.eww.package = pkgs.eww;

  systemd.user.services.clipcat.Service = {
    ExecStartPre = lib.mkForce "${pkgs.writeShellScript "clipcatd-exec-start-pre" ''
      PATH=${config.home.homeDirectory}/.nix-profile/bin:/nix/var/nix/profiles/default/bin::/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
      rm -f %t/clipcat/grpc.sock
    ''}";
    ExecStart = lib.mkForce "${pkgs.writeShellScript "clipcatd-exec-start" ''
      PATH=${config.home.homeDirectory}/.nix-profile/bin:/nix/var/nix/profiles/default/bin::/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
      ${config.services.clipcat.package}/bin/clipcatd --no-daemon --replace
    ''}";
  };

  home.username = "ccomar";
  home.homeDirectory = "/home/ccomar";
  home.packages = with pkgs; [
    cachix
    git-crypt
    complete_alias
    kubernetes_aliases
    iosevka-nerd-font
    inconsolata
    inconsolata-lgc
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
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
    noto-fonts
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
    xbacklight
    pamixer
    pavucontrol
    brightnessctl
    bc
    gnupg
    # pinentry-curses
    pinentry-gnome3
    paperkey
    virt-manager
    pulseeffects-legacy
    p7zip
    unrar
    unzip
    thunderbolt
    pciutils
    nix-zsh-completions
    yubikey-personalization
    (hwloc.override {
      x11Support = true;
      cairo = pkgs.cairo;
    })
    vulkan-tools
    mesa-demos
    mermaid-cli
    nvtopPackages.full
    gh
    nix-output-monitor
    opentofu
    tofu-ls
    prettier
    terragrunt
    nh
  ];

  programs.rbw = {
    enable = true;
    settings = {
      email = "cass@ndra.io";
      pinentry = pkgs.pinentry-rofi;
      lock_timeout = 3600;
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = git_config.userName;
        email = git_config.userEmail;
      };
      pull.rebase = false;
      inherit (git_config) github;
      # tag = {
      #   gpgsign = git_config.signing.signByDefault;
      # };
      gpg = {
        program = "${pkgs.gnupg}/bin/gpg2";
      };
      # includeIf."gitdir:/home/cassandra/src/git.drwholdings.com/".path = "/home/cassandra/.work.gitconfig";
      # includeIf."gitdir:/home/cassandra/src/github.com/".path = "/home/cassandra/.personal.gitconfig";
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
        extensions = {
          packages = with pkgs.nur.repos.rycee.firefox-addons; [
            multi-account-containers
            sidebery
            bitwarden
            ublock-origin
            vimium
            sponsorblock
            darkreader
            don-t-fuck-with-paste
          ];
        };
        settings = {
          "widget.use-xdg-desktop-portal.file-picker" = "1";
          "toolkit.legacyUserProfileCustomizations.stylesheets" = "true";
          # without this, sidebery starts disabled and the below stylesheet hides all tabs
          # this makes firefox a little annoying to set up initially.
          "extensions.autoDisableScopes" = 0;
        };
        search = {
          force = true;
          default = "paulgo";
          privateDefault = "paulgo";

          engines = {
            nix-packages = {
              name = "Nix Packages";
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];

              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@np"];
            };

            nix-options = {
              name = "Nix Options";
              urls = [
                {
                  template = "https://search.nixos.org/options";
                  params = [
                    {
                      name = "type";
                      value = "options";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];

              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@no"];
            };

            home-manager = {
              name = "home-manager Options";
              urls = [
                {
                  template = "https://home-manager-options.extranix.com";
                  params = [
                    {
                      name = "release";
                      value = "master";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];

              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["@hm"];
            };

            nixos-wiki = {
              name = "NixOS Wiki";
              urls = [{template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";}];
              iconMapObj."16" = "https://wiki.nixos.org/favicon.ico";
              definedAliases = ["@nw"];
            };

            paulgo = {
              name = "paulgo.io";
              urls = [{template = "https://paulgo.io/?q={searchTerms}";}];
            };

            bing.metaData.hidden = true;
            google.metaData.alias = "@g";
          };
        };
        userChrome = ''
          #TabsToolbar > * {
            visibility: collapse !important;
          }

          #sidebar-box[sidebarcommand="_3c078156-979c-498b-8990-85f7987dd929_-sidebar-action"]
            > #sidebar-header {
            display: none;
          }

          #navigator-toolbox {
            --uc-menubar-height: 17px;
          }
          :root[uidensity="compact"] #navigator-toolbox {
            --uc-menubar-height: 15px;
          }
        '';
      };
    };
  };

  programs.mbsync.enable = true;
  programs.msmtp.enable = true;
  programs.notmuch = {
    enable = true;
    hooks = {
      preNew = "${pkgs.isync}/bin/mbsync -L --all";
      postNew = "${pkgs.afew}/bin/afew --tag --new --verbose";
    };
    new = {
      ignore = ["trash" "*.json"];
      tags = ["new"];
    };
    search.excludeTags = ["trash" "deleted" "spam"];
    maildir.synchronizeFlags = true;
  };
  programs.afew = {
    enable = true;
    extraConfig = ''
      [SpamFilter]
      [KillThreadsFilter]
      [ListMailsFilter]
      [ArchiveSentMailsFilter]

      [FolderNameFilter.1]
      folder_transforms = cass@nie.rs:nie.rs cass@mountclare.net:mountclare.net
      maildir_separator = /
      folder_lowercases = true

      [InboxFilter]
    '';
  };
  services.imapnotify.enable = true;

  accounts.email = {
    maildirBasePath = "${config.xdg.dataHome}/maildir";
    accounts = {
      "cass@nie.rs" = {
        address = "cass@nie.rs";
        passwordCommand = "${pkgs.rbw}/bin/rbw get purelymail.com cass@nie.rs";
        mbsync = {
          enable = true;
          create = "both";
        };
        primary = false;
        realName = "Cassandra Comar";
        imap.host = "imap.purelymail.com";
        smtp = {
          host = "smtp.purelymail.com";
        };
        msmtp.enable = true;
        notmuch.enable = true;
        imapnotify = {
          enable = true;
          onNotify = "${pkgs.notmuch}/bin/notmuch new && ${pkgs.notifymuch}/bin/notifymuch";
        };
        userName = "cass@nie.rs";
      };
      "cass@mountclare.net" = {
        address = "cass@mountclare.net";
        passwordCommand = "${pkgs.rbw}/bin/rbw get purelymail.com cass@mountclare.net";
        mbsync = {
          enable = true;
          create = "both";
        };
        primary = false;
        realName = "Cassandra Comar";
        imap.host = "imap.purelymail.com";
        smtp = {
          host = "smtp.purelymail.com";
        };
        msmtp.enable = true;
        notmuch.enable = true;
        imapnotify = {
          enable = true;
          onNotify = "${pkgs.notmuch}/bin/notmuch new && ${pkgs.notifymuch}/bin/notifymuch";
        };
        userName = "cass@mountclare.net";
      };
      "ccomar@drwholdings.com" = {
        address = "ccomar@drwholdings.com";
        passwordCommand = "${pkgs.rbw}/bin/rbw get drwholdings.com ccomar";
        mbsync = {
          enable = true;
          create = "both";
        };
        primary = true;
        realName = "Cassandra Comar";
        imap = {
          host = "127.0.0.1";
          port = 1143;
          tls.enable = false;
        };
        smtp = {
          host = "127.0.0.1";
          port = 1025;
          tls.enable = false;
        };
        msmtp.enable = true;
        notmuch.enable = true;
        imapnotify = {
          enable = true;
          onNotify = "${pkgs.notmuch}/bin/notmuch new && ${pkgs.notifymuch}/bin/notifymuch";
        };
        userName = "ccomar@drwholdings.com";
      };
    };
  };

  home.stateVersion = "21.11";
}
