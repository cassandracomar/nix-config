{
  lib,
  pkgs,
  host,
  ...
}: let
  git_config_by_host = {
    cherry = {
      userName = "Cassandra Comar";
      userEmail = "cass@ndra.io";
      signing = {
        key = "0xF431E5E70CAB3E2E";
        signByDefault = true;
      };
      github.user = "cassandracomar";
    };
    magus = {
      userName = "Cassandra Comar";
      userEmail = "cass@ndra.io";
      signing = {
        key = "0xF431E5E70CAB3E2E";
        signByDefault = true;
      };
      github.user = "cassandracomar";
    };
    yew = {
      userName = "Cassandra Comar";
      userEmail = "cass@ndra.io";
      # signing = {
      #   key = "0xF431E5E70CAB3E2E";
      #   signByDefault = true;
      # };
      github.user = "cassandracomar";
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

  home.username = "cassandra";
  home.homeDirectory = "/home/cassandra";
  home.packages = with pkgs; [
    gitAndTools.delta
    git-crypt
    complete_alias
    kubernetes_aliases
  ];
  home.sessionVariables.GITHUB_USER = git_config.github.user;
  # home.file."personal.gitconfig" = {
  #   target = ".personal.gitconfig";
  #   source = pkgs.writeTextFile {
  #     name = ".personal.gitconfig";
  #     text = ''
  #       [user]
  #       	email = "${git_config.userEmail}"
  #       	name = "${git_config.userName}"
  #       	signingKey = "${git_config.signing.key}"
  #     '';
  #   };
  # };
  # home.file.".work.gitconfig" = {
  #   target = ".work.gitconfig";
  #   source = pkgs.writeTextFile {
  #     name = ".work.gitconfig";
  #     text = ''
  #       [user]
  #       	email = "ccomar@drwholdings.com"
  #       	name = "Cassandra Comar"
  #       	signingKey = "0x0DF1B6D8D3880CC2"
  #     '';
  #   };
  # };

  home.file.nixos-rebuild = {
    source = ../scripts/nixos-rebuild;
    target = ".local/bin/nixos-rebuild";
    executable = true;
  };

  home.file.build-android = {
    source = ../scripts/build-android;
    target = ".local/bin/build-android";
    executable = true;
  };

  programs.rbw = {
    enable = true;
    settings = {
      email = "cass@ndra.io";
      pinentry = pkgs.pinentry-rofi;
    };
  };

  programs.git = {
    enable = true;
    # delta.enable = true;
    extraConfig = {
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
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          reddit-enhancement-suite
          multi-account-containers
          sidebery
          bitwarden
          ublock-origin
          vimium
          sponsorblock
          darkreader
          don-t-fuck-with-paste
        ];
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = "true";
        };
        userChrome = ''
          :root {
            --uc-toolbar-height: 16px;
          }
          :root:not([uidensity="compact"]) {
            --uc-toolbar-height: 17px;
          }

          #TabsToolbar > * {
            visibility: collapse !important;
          }

          #nav-bar {
            margin-top: calc(0px - var(--uc-toolbar-height));
            /* margin-left: 60px; */
          }
          :root[inFullscreen] #navigator-toolbox {
            margin-top: 11px;
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

          #titlebar {
            flex-direction: column-reverse;
            -moz-appearance: none !important;
          }

          #toolbar-menubar {
            margin-bottom: calc(0px - var(--uc-menubar-height));
            height: var(--uc-menubar-height);
            position: relative;
            z-index: 2;
            pointer-events: none;
          }

          #menubar-items {
            justify-content: left;
            pointer-events: initial;
            margin-top: 3px;
            color: var(--toolbar-color);
          }

          #toolbar-menubar > .titlebar-buttonbox-container {
            display: none;
          }
          :root[tabsintitlebar][sizemode="normal"] .titlebar-spacer,
          :root[tabsintitlebar] #TabsToolbar > .titlebar-buttonbox-container {
            display: flex !important;
          }
        '';
      };
    };
  };

  home.stateVersion = "21.11";
}
