{ lib, pkgs, pkgs-master, host, ... }:

let
  git_config_by_host = {
    cherry = {
      userName = "Cassandra Comar";
      userEmail = "cassandra@ditto.live";
      signing = {
        key = "0xF431E5E70CAB3E2E";
        signByDefault = true;
      };
      github.user = "cassandracomar";
    };
    magus = {
      userName = "Cassandra Comar";
      userEmail = "cassandra@ditto.live";
      signing = {
        key = "0xF431E5E70CAB3E2E";
        signByDefault = true;
      };
      github.user = "cassandracomar";
    };
    yew = {
      userName = "Cassandra Comar";
      userEmail = "cassandra@ditto.live";
      signing = {
        key = "0xF431E5E70CAB3E2E";
        signByDefault = true;
      };
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

      alias cictl="kubectl --context=cassandracomar@ci.k8s.ditto.live"
      complete -F _complete_alias cictl

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
in
{
  imports = [ ./base ];

  home.username = "cassandra";
  home.homeDirectory = "/home/cassandra";
  home.packages = with pkgs; [
    gitAndTools.delta
    git-crypt
    complete_alias
    kubernetes_aliases
  ];
  home.sessionVariables.GITHUB_USER = git_config.github.user;

  home.file.nixos-rebuild = {
    source = ../scripts/nixos-rebuild;
    target = ".local/bin/nixos-rebuild";
    executable = true;
  };

  programs.git = {
    inherit (git_config) userName userEmail signing;
    enable = true;
    delta.enable = true;
    extraConfig = {
      pull.rebase = false;
      inherit (git_config) github;
    };
  };

  programs.firefox = {
    enable = true;
    package = pkgs-master.firefox-nightly-bin.override {
      extraPolicies = { DisableAppUpdate = true; };
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

  home.stateVersion = "21.11";
}
