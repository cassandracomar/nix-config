{pkgs, ...}: let
  git_config = {
    userName = "Cassandra Comar";
    userEmail = "cass@ndra.io";
    github.user = "cassandracomar";
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

  programs.rbw = {
    enable = true;
    settings = {
      email = "cass@ndra.io";
      pinentry = pkgs.pinentry-rofi;
    };
  };

  programs.git = {
    enable = true;
    userName = git_config.userName;
    userEmail = git_config.userEmail;
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
      preNew = "mbsync --all";
    };
  };
  programs.afew.enable = true;

  accounts.email.accounts.cass = {
    address = "cass@nie.rs";
    passwordCommand = "rbw get purelymail.com 'cass@nie.rs'";
    notmuch.enable = true;
    mbsync = {
      enable = true;
      create = "both";
    };
    primary = true;
    realName = "Cassandra Comar";
    imap.host = "imap.purelymail.com";
    smtp = {
      host = "smtp.purelymail.com";
    };
    msmtp.enable = true;
    userName = "cass@nie.rs";
  };

  home.stateVersion = "21.11";
}
