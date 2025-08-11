{
  # pkg registries
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  # inputs.nixpkgs-master.url = "github:NixOS/nixpkgs/master";
  inputs.nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.xmonad-personal.url = "github:cassandracomar/dotxmonad";
  # inputs.robotnix.url = "github:cassandracomar/robotnix/fix-cts-profile";

  # encryption
  # inputs.sops-nix.url = "github:Mic92/sops-nix";

  # overlays
  inputs.mozilla = {url = "github:mozilla/nixpkgs-mozilla";};
  inputs.emacs.url = "github:nix-community/emacs-overlay";
  inputs.emacs-src.url = "github:emacs-mirror/emacs/emacs-29";
  inputs.emacs-src.flake = false;
  inputs.rust.url = "github:oxalica/rust-overlay";
  inputs.rust.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nur.url = "github:nix-community/NUR";
  inputs.openconnect = {
    url = "github:vlaci/openconnect-sso";
    flake = false;
  };

  # overrides via overlay
  inputs.nix-direnv.url = "github:nix-community/nix-direnv";
  inputs.nix-direnv.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixos-generators.url = "github:nix-community/nixos-generators";
  inputs.nixos-generators.inputs.nixpkgs.follows = "nixpkgs-stable";
  # inputs.nixos-hardware.url = "github:cassandracomar/nixos-hardware";
  inputs.nixos-hardware.url = "path:/Users/ccomar/src/git.drwholdings.com/nixos/nixos-hardware";

  inputs.poetry2nix.url = "github:nix-community/poetry2nix";

  # nixConfig = {
  #   sandbox-paths = ["/data/androidKeys" "/var/www/updater.ndra.io"];
  # };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    xmonad-personal,
    mozilla,
    emacs,
    emacs-src,
    rust,
    nur,
    nix-direnv,
    openconnect,
    nixos-generators,
    poetry2nix,
    ...
  } @ inputs: let
    hosts = ["cherry" "walnut" "magus" "yew"];
    homeUsers = ["cassandra"];
    nonNixosUsers = [
      {
        host = "rnwld-ccomar1";
        os = "ubuntu";
        user = "ccomar";
      }
    ];
    system = "x86_64-linux";

    overlays = [
      mozilla.overlay
      emacs.overlay
      rust.overlays.default
      nur.overlay
      (final: prev: let
        poetry2nixBuilder = poetry2nix.lib.mkPoetry2Nix {pkgs = prev;};
        iosevka-fonts = prev.callPackage ./packages/iosevka.nix {
          poetry2nix = poetry2nixBuilder;
        };
      in
        {
          inherit (iosevka-fonts) iosevka-nerd-font pyftfeatfreeze iosevka-custom;
        })
      (final: prev: {
        calibre = prev.calibre.overrideAttrs (oldAttrs: {
          # We want to have pycryptodome around in order to support DeDRM
          nativeBuildInputs =
            oldAttrs.nativeBuildInputs
            ++ [prev.python3Packages.pycryptodome];
        });

        nix-direnv = nix-direnv.defaultPackage.${system};
        vcluster =
          import ./packages/vcluster.nix {inherit (final) fetchurl stdenv;};
      })
      (
        final: prev:
          import ./packages/actualbudget/override.nix {
            pkgs = prev;
            inherit system;
          }
      )

      (final: prev: let
        kpkgs = nixpkgs.legacyPackages.${system};
      in {
        CoreFreq = prev.callPackage ./packages/corefreq.nix {
          kernelPackage = prev.linux_xanmod_latest;
        };
      })

      (final: prev: {
        xmonad-personal = xmonad-personal.defaultPackage.${system};
      })

      (import "${openconnect}/overlay.nix")
    ];

    pkgs = import nixpkgs {
      inherit system overlays;
      config.allowUnfree = true;

      config.packageOverides = pkgs:
        with pkgs; {
          steam = steam.override {
            nativeOnly = true;
            extraLibraries = [pipewire.lib networkmanager];
            extraPkgs = [pipewire.lib];
          };
        };
    };

    kernel = {
      pkgs,
      config,
      ...
    }: {
      boot.kernelPackages =
        pkgs.lib.mkDefault (pkgs.linuxKernel.packagesFor
          pkgs.linuxKernel.kernels.linux_xanmod_latest);
      # bug fix for performance regression for zfs since 5.3
      boot.kernelParams = ["init_on_alloc=0" "init_on_free=0"];
      boot.zfs.package = pkgs.zfs_unstable;

      boot.kernel.sysctl."fs.inotify.max_user_instances" = 8192;
    };

    # sops-config = {
    #   sops.defaultSopsFile = ./.sops.yaml;
    #   sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    # };

    base-modules = [kernel ./modules ./system/base];
    user-module = username: {
      name = username;
      value = {
        imports = [
          (import ./user.nix {inherit username;})
          {
            manual.manpages.enable = false;
            home.packages = [
              xmonad-personal.defaultPackage.${system}
            ];
          }
        ];
      };
    };

    iso = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.allowBroken = true;
      };
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
        "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
        ./iso/installer.nix
      ];
    };

    nixosConfigurations =
      pkgs.lib.listToAttrs
      (map
        (host: {
          name = host;
          value = nixpkgs.lib.nixosSystem {
            inherit pkgs;
            modules =
              base-modules
              ++ [
                (import ./host.nix {inherit host;})
                # robotnix.nixosModule
                home-manager.nixosModules.home-manager
              ]
              ++ (pkgs.lib.foldl
                (m: user:
                  m
                  ++ [
                    {
                      home-manager.useGlobalPkgs = true;
                      home-manager.useUserPackages = true;
                      home-manager.users = pkgs.lib.listToAttrs (map
                        user-module
                        [user]);
                      home-manager.extraSpecialArgs = {inherit pkgs user host nixpkgs system;};
                    }
                  ]) []
                homeUsers);
            specialArgs = {inherit system nixpkgs inputs;};
          };
        })
        hosts)
      // {
        inherit iso;
      };

    nonNixosHomeConfigs = pkgs.lib.listToAttrs (map
      (userDef: {
        name = "${userDef.user}@${userDef.host}";
        value = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [(user-module userDef.user).value];
          extraSpecialArgs = {
            inherit (userDef) user os host;
          };
        };
      })
      nonNixosUsers);

    # androidImages = pkgs.lib.listToAttrs (map
    #   (device: {
    #     name = device;
    #     value = robotnix.lib.robotnixSystem {
    #       inherit device;
    #       flavor = "grapheneos";
    #       apv.enable = false;
    #       adevtool.hash = "sha256-FZ5MAr9xlhwwT6OIZKAgC82sLn/Mcn/RHwZmiU37jxc=";
    #       # buildNumber = "2023050101";
    #       # buildDateTime = 1683319618;
    #       cts-profile-fix.enable = true;
    #       signing = {
    #         enable = true;
    #         keyStorePath = ./keys/android;
    #         sopsDecrypt = {
    #           enable = true;
    #           sopsConfig = ./.sops.yaml;
    #           key = "/data/androidKeys/keys.txt";
    #           keyType = "age";
    #         };
    #       };
    #       apps = {
    #         updater = {
    #           enable = true;
    #           url = "https://updater.ndra.io";
    #           includedInFlavor = true;
    #         };
    #       };
    #       prevBuildDir = "/var/www/updater.ndra.io";
    #       incremental = true;
    #     };
    #   }) ["panther"]);
  in {
    inherit nixosConfigurations;
    packages.${system} = pkgs;
    build =
      pkgs.lib.mapAttrs
      (
        name: value:
          value.config.system.build
      )
      nixosConfigurations;

    homeConfigurations =
      pkgs.lib.foldl
      (homeConfig: host:
        homeConfig
        // pkgs.lib.listToAttrs
        (map
          (user: {
            name = "${user}@${host}";
            value = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [(user-module user).value];
              extraSpecialArgs = {inherit host nixpkgs system user;};
            };
          })
          homeUsers))
      {}
      hosts
      // nonNixosHomeConfigs;

    # packages.aarch64-linux.banyan-image = let
    #   pkgs-aarch64 = import self.inputs.nixpkgs-stable {
    #     system = "aarch64-linux";
    #     config.allowUnfree = true;
    #     config.allowUnsupportedSystem = true;
    #   };
    # in
    #   self.inputs.nixos-generators.nixosGenerate rec {
    #     inherit (pkgs-aarch64) lib;
    #     format = "sd-image-nanopi-r5c";
    #     pkgs = pkgs-aarch64;
    #     customFormats = {
    #       sd-image-nanopi-r5c = import machines/banyan.nix {
    #         inherit self lib pkgs;
    #       };
    #     };
    #   };

    formatter.${system} = pkgs.alejandra;
    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
  };
}
