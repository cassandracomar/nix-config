{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: let
  git_config = {
    userName = "Cassandra Comar";
    userEmail = "ccomar@drwholdings.com";
    github = {
      user = "cassandracomar";
      "git.drwholdings.com/api/v3".user = "ccomar";
      "git.drwholdings.com/api".user = "ccomar";
      "git.drwholdings.com".user = "ccomar";
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
  drwMailSyncScript = pkgs.writeShellScriptBin "mail-sync-ccomar-drwholdings" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [
      pkgs.isync
      config.programs.notmuch.package
      pkgs.afew
      pkgs.notifymuch
      pkgs.coreutils
    ]}

    # afew --verbose logs to stderr; route everything to journal
    exec 2>&1

    start=$(date +%s)
    echo "=== sync start $(date -Iseconds) ==="

    mbsync -Ln ccomar@drwholdings.com
    notmuch new --no-hooks --verbose

    pre=$(notmuch count tag:new)
    echo "tag:new count BEFORE afew: $pre"

    afew --tag --new --verbose

    post=$(notmuch count tag:new)
    echo "tag:new count AFTER afew: $post"
    if [ "$post" -gt 0 ]; then
      echo "WARN messages still tagged new after afew:"
      notmuch search --output=summary tag:new | head -50
    fi

    notifymuch

    echo "=== sync end elapsed=$(( $(date +%s) - start ))s ==="
  '';

  emacs' = pkgs.emacs-igc-pgtk.overrideAttrs (old: {
    stdenv = pkgs.llvmPackages.stdenv;
    patches = builtins.filter (p: baseNameOf (toString p) != "tree-sitter-0.26.patch") old.patches;
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

  systemd.user.services.mail-sync-ccomar-drwholdings = {
    Unit = {
      Description = "Sync mail for ccomar@drwholdings.com";
      After = ["anyconnect.service" "davmail.service"];
      Wants = ["davmail.service"];
      PartOf = ["anyconnect.service"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${drwMailSyncScript}/bin/mail-sync-ccomar-drwholdings";
    };
  };
  systemd.user.timers.mail-sync-ccomar-drwholdings = {
    Unit = {
      Description = "Periodic mail sync for ccomar@drwholdings.com";
      PartOf = ["anyconnect.service"];
    };
    Timer = {
      OnCalendar = "*:0/5";
      Persistent = true;
      Unit = "mail-sync-ccomar-drwholdings.service";
    };
    Install = {
      WantedBy = ["anyconnect.service"];
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
        version = "595.71.05";
        sha256 = "sha256-NiA7iWC35JyKQva6H1hjzeNKBek9KyS3mK8G3YRva4I=";
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
  systemd.user.services.pinnacle.Service.Environment = ["PINNACLE_DRM_DEVICES=/dev/dri/card1:/dev/dri/renderD128" "WGPU_POWER_PREF=low"];
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
    # noto-fonts
    # noto-fonts-cjk-sans
    # noto-fonts-color-emoji
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
    nodejs-slim
    prettier
  ];

  programs.rbw = {
    enable = true;
    settings = {
      email = "cass@ndra.io";
      pinentry = pkgs.pinentry-rofi;
      lock_timeout = 86400;
    };
  };

  systemd.user.services.rbw-agent = {
    Unit = {
      Description = "rbw (Bitwarden) credentials agent";
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.rbw}/bin/rbw-agent --no-daemonize";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = ["graphical-session.target"];
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
      signing.format = "openpgp";
      # includeIf."gitdir:/home/cassandra/src/git.drwholdings.com/".path = "/home/cassandra/.work.gitconfig";
      # includeIf."gitdir:/home/cassandra/src/github.com/".path = "/home/cassandra/.personal.gitconfig";
    };
  };

  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
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

  programs.afew.extraConfig = ''
    [FolderNameFilter.2]
    folder_transforms = ccomar@drwholdings.com:drwholdings.com
    maildir_separator = /
    folder_lowercases = true

    [Filter.2]
    query = 'to:github@drwholdings.com'
    tags = +github;-new;-inbox
    message = very spammy

    [Filter.3]
    query = 'from:splunk-chi@drwholdings.com AND subject:Risk'
    tags = +risk;+splunk;-new;-inbox
    message = very spammy

    [Filter.4]
    query = 'from:app@statushero.com or from:notifications@app.steady.space or team@mail.steady.space'
    tags = +statushero;-new;-inbox
    message = spam

    [Filter.5]
    query = 'subject:"Posit Connect"'
    tags = +risk;-new;-inbox
    message = irrelevant

    [Filter.6]
    query = 'from:no-reply@pagerduty.com'
    tags = +pagerduty;+alerts;+important;-inbox
    message = keep an eye on these separately

    [Filter.7]
    query = 'from:drw@service-now.com'
    tags = +servicenow;-new;-inbox
    message = these are mostly irrelevant

    [Filter.8]
    query = 'to:/up-.*-alerts@drw/'
    tags = +alerts;+important;-inbox
    message = keep an eye on these separately

    [Filter.9]
    query = 'from:srv_sentry@drwholdings.com'
    tags = +sentry;-inbox;-new
    message = spammy and of questionable relevance

    [Filter.10]
    query = 'from:daily@updates.miro.com'
    tags = +miro;-inbox;-new
    message = spam

    [Filter.11]
    query = 'from:VSPVisionCareVCM@e.vsp.com'
    tags = +vsp;-inbox;-new
    message = spam

    [Filter.12]
    query = 'from:servicectr@bloomberg.net'
    tags = +bloomberg;-inbox;-new
    message = spam

    [Filter.13]
    query = 'from:Communications@DRWHoldings.com'
    tags = +communications;-inbox;-new
    message = too noisy

    [Filter.14]
    query = tag:lists/sample-splunk-log
    tags = +sentry;-inbox;-new
    message = too noisy and belongs to a different team

    [Filter.15]
    query = from:alertmanager-gem-unix@drw.com
    tags = +alertmanager;+alerts;+important;-inbox
    message = keep an eye on these separately

    [Filter.16]
    query = 'from:team@mail.miro.com or from:important@notification.miro.com'
    tags = +miro;-inbox;-new
    message = spam

    [Filter.17]
    query = 'from:configserver'
    tags = +k8s;+releases;-inbox;-new
    message = Tools Promotion Notification etc. from config-api pods

    [Filter.18]
    query = 'from:srv_email_reports@drwholdings.com'
    tags = +reports;-inbox;-new
    message = automated server/patching reports

    [Filter.19]
    query = 'from:iss@drw.com'
    tags = +iss;-inbox;-new
    message = certificate expiry / ISS auto-notifications

    [Filter.20]
    query = 'from:github@drwholdings.com'
    tags = +github;-new;-inbox
    message = github by sender, catches what to:github@drw misses

    [Filter.21]
    query = 'from:jira-prod@drw.com and subject:TDA'
    tags = +tda;-inbox;-new
    message = TDA Global Notify broadcasts from Jira

    [Filter.22]
    query = from:no-reply@thecurrency.empower.com or from:no-reply@email.empower.com
    tags = +empower;-inbox;-new
    message = spam

    [Filter.23]
    query = 'from:srv_observability@drwholdings.com'
    tags = +observability;-inbox;-new
    message = noisy

    [Filter.24]
    query = from:do-not-reply-support@lastpass.com
    tags = +lastpass;-inbox;-new
    message = shared-folder notifications

    [Filter.25]
    query = from:announce@crunchydata.com
    tags = +crunchy;-inbox;-new
    message = release/advisory announcements

    [Filter.26]
    query = from:grmtechnology-do_not_reply@drw.com
    tags = +grm;-inbox;-new
    message = RMG report download confirmations

    [Filter.27]
    query = from:caresupport@hello.springhealth.com
    tags = +springhealth;-inbox;-new
    message = wellness reminders

    [Filter.28]
    query = from:no-reply@zoom.us or from:noreply-marketplace@zoom.us
    tags = +zoom;-inbox;-new
    message = "X joined your meeting" / app marketplace

    [InboxFilter]
  '';

  accounts.email = {
    accounts = {
      "ccomar@drwholdings.com" = {
        address = "ccomar@drwholdings.com";
        passwordCommand = "${pkgs.rbw}/bin/rbw get drwholdings.com ccomar";
        mbsync = {
          enable = true;
          create = "both";
          extraConfig.account = {
            AuthMechs = ["LOGIN"];
            Timeout = 1200;
          };
        };
        primary = true;
        realName = "Cassandra Comar";
        imap = {
          host = "127.0.0.32";
          port = 1143;
          tls.enable = false;
        };
        smtp = {
          host = "127.0.0.32";
          port = 1025;
          tls.enable = false;
        };
        msmtp = {
          enable = true;
          extraConfig = {
            auth = "login";
            tls = "off";
          };
        };
        notmuch.enable = true;
        imapnotify.enable = false;
        userName = "ccomar";
      };
    };
  };

  services.davmail = {
    enable = true;
    settings = {
      "davmail.server" = true;
      "davmail.allowRemote" = false;
      "davmail.bindAddress" = "127.0.0.32";
      "davmail.mode" = "O365";
      "davmail.url" = "https://webmail.drwholdings.com/ews/exchange.asmx";
      "davmail.loginUrl" = "https://adfs.drwholdings.com/adfs/ls";
      "davmail.defaultDomain" = "us";
      "davmail.outlookUrl" = "https://webmail.drwholdings.com/owa/";
      "davmail.oauth.clientId" = "d3590ed6-52b3-4102-aeff-aad2292ab01c";
      "davmail.oauth.redirectUri" = "http://127.0.0.32/owa/common/oauth2/nativeclient";
      "davmail.enableGraph" = true;
      "davmail.enableOidc" = false;
      "davmail.graphUrl" = "https://webmail.drwholdings.com/owa/graph";
      "davmail.graphPrefix" = "beta";
      "davmail.folderSizeLimit" = 10000;
      "log4j.logger.davmail" = "INFO";
      "log4j.logger.httpclient.wire" = "WARN";
      "log4j.logger.org.apache.commons.httpclient" = "WARN";
      "log4j.rootLogger" = "WARN";
    };
  };

  # the hardening settings applied to davmail are so severe that systemd can't even exec the process.
  # turn these down so the process can actually be started.
  systemd.user.services.davmail.Service = {
    LockPersonality = lib.mkForce false;
    PrivateDevices = lib.mkForce false;
    ProtectClock = lib.mkForce false;
    ProtectControlGroups = lib.mkForce false;
    ProtectKernelLogs = lib.mkForce false;
    ProtectKernelModules = lib.mkForce false;
    ProtectKernelTunables = lib.mkForce false;
    CapabilityBoundingSet = lib.mkForce "~";
    Environment = ["JAVA_OPTS='-Xmx10G -Dsun.net.inetaddr.ttl=60 -Djdk.gtk.version=3'"];
  };

  # vdirsyncer requires pair/storage names to match [A-Za-z0-9_] only, so the
  # account keys use underscores (referenced by khal's default_calendar and
  # the khalel use-package block in doom-config/config.el).
  accounts.calendar = {
    basePath = ".local/share/calendars";
    accounts.ccomar_personal = {
      primary = true;
      local = {
        type = "filesystem";
        fileExt = ".ics";
      };
      remote = {
        type = "caldav";
        url = "http://127.0.0.32:1080/users/ccomar@drwholdings.com/calendar/";
        userName = "ccomar";
        passwordCommand = ["${pkgs.rbw}/bin/rbw" "get" "drwholdings.com" "ccomar"];
      };
      # Explicit collection aliasing: [pair-name, name-in-storage-a, name-in-b].
      # home-manager wires a=remote, b=local, so the triplet reads:
      # [pair-name, remote-collection, local-subdir]. Gives khal stable names
      # ("personal", "pagerduty") instead of "calendar"/"calendar1".
      vdirsyncer = {
        enable = true;
        collections = [
          ["personal" "calendar" "personal"]
          ["pagerduty" "Pagerduty Primary" "pagerduty"]
        ];
        conflictResolution = "remote wins";
      };
      khal = {
        enable = true;
        type = "discover";
        color = "light blue";
      };
    };
    accounts.up_platform_infra = {
      local = {
        type = "filesystem";
        fileExt = ".ics";
      };
      remote = {
        type = "caldav";
        url = "http://127.0.0.32:1080/users/up-platform-infrastructure-calendar@drwholdings.com/calendar/";
        userName = "ccomar";
        passwordCommand = ["${pkgs.rbw}/bin/rbw" "get" "drwholdings.com" "ccomar"];
      };
      vdirsyncer = {
        enable = true;
        collections = [
          ["team" "calendar" "team"]
        ];
        conflictResolution = "remote wins";
      };
      khal = {
        enable = true;
        type = "discover";
        color = "light green";
      };
    };
  };

  programs.vdirsyncer.enable = true;
  services.vdirsyncer = {
    enable = true;
    frequency = "*:0/15";
  };

  systemd.user.services.vdirsyncer = {
    Install.WantedBy = ["anyconnect.service"];
    Unit = {
      Wants = ["davmail.service"];
      After = ["davmail.service" "anyconnect.service"];
      PartOf = ["anyconnect.service"];
      OnSuccess = ["khalel-import.service"];
    };
    Service.ExecStartPre = "${pkgs.runtimeShell} -c 'until ${pkgs.netcat-openbsd}/bin/nc -z 127.0.0.32 1080; do sleep 1; done'";
  };

  systemd.user.services.khalel-import = let
    importScript = pkgs.writeText "khalel-import-batch.el" ''
      ;;; khalel-import-batch.el --- batch import per khal calendar -*- lexical-binding: t; -*-
      (setq make-backup-files nil
            backup-directory-alist '(("." . "~/.cache/doom/nix/backup/")))
      (add-to-list 'load-path "${inputs.doom-config}")
      (require '+khalel)
      (setq khalel-khal-command "${pkgs.khal}/bin/khal")
      (+khalel-import-events-per-calendar)
      (kill-emacs 0)
    '';
  in {
    Unit = {
      Description = "Import each khal calendar into its own ~/todo/calendar-*.org file (batch)";
      After = ["vdirsyncer.service"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.programs.doom-emacs.finalEmacsPackage}/bin/emacs --batch -l ${importScript}";
    };
  };

  programs.khal = {
    enable = true;
    locale = {
      timeformat = "%H:%M";
      dateformat = "%Y-%m-%d";
      longdateformat = "%Y-%m-%d %a";
      datetimeformat = "%Y-%m-%d %H:%M";
      longdatetimeformat = "%Y-%m-%d %a %H:%M";
    };
    settings = {
      default = {
        default_calendar = "personal";
        timedelta = "30d";
        highlight_event_days = "True";
      };
      view = {
        agenda_event_format = "{calendar-color}{cancelled}{start-end-time-style} {title}{repeat-symbol}{reset}";
      };
    };
  };

  home.stateVersion = "26.05";
}
