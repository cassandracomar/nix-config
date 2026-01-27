{
  # pkg registries
  inputs.nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
  # inputs.nixpkgs-master.url = "github:NixOS/nixpkgs/master";
  inputs.nixpkgs-stable.url = "https://channels.nixos.org/nixos-25.11/nixexprs.tar.xz";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/master";
  inputs.cachyos-kernel.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nix-index.url = "github:nix-community/nix-index";
  inputs.nix-index.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nix-index-database.url = "github:nix-community/nix-index-database";
  inputs.nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  # inputs.robotnix.url = "github:cassandracomar/robotnix/fix-cts-profile";

  # overlays
  inputs.mozilla = {url = "github:mozilla/nixpkgs-mozilla";};
  inputs.emacs.url = "github:nix-community/emacs-overlay";
  inputs.nur.url = "github:nix-community/NUR";

  # overrides via overlay
  # inputs.nix-direnv.url = "github:nix-community/nix-direnv";
  # inputs.nix-direnv.inputs.nixpkgs.follows = "nixpkgs";

  # inputs.nixos-generators.url = "github:nix-community/nixos-generators";
  # inputs.nixos-generators.inputs.nixpkgs.follows = "nixpkgs-stable";
  # inputs.nixos-hardware.url = "github:cassandracomar/nixos-hardware";
  # inputs.nixos-hardware.url = "path:/Users/ccomar/src/git.drwholdings.com/nixos/nixos-hardware";

  inputs.poetry2nix.url = "github:nix-community/poetry2nix";
  inputs.pinnacle.url = "github:pinnacle-comp/pinnacle";
  inputs.pinnacle-config.url = "github:cassandracomar/pinnacle-config";
  inputs.pinnacle-config.inputs.pinnacle.follows = "pinnacle";
  inputs.clipcat.url = "github:xrelkd/clipcat";
  inputs.clipcat.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-doom.url = "github:marienz/nix-doom-emacs-unstraightened";
  inputs.nix-doom.inputs.nixpkgs.follows = "";
  inputs.nix-doom.inputs.emacs-overlay.follows = "emacs";
  inputs.doom-config.url = "github:cassandracomar/doom-config";
  inputs.doom-config.flake = false;

  inputs.nixgl.url = "github:nix-community/nixGL";
  # nixConfig = {
  #   sandbox-paths = ["/data/androidKeys" "/var/www/updater.ndra.io"];
  # };

  outputs = {
    nixpkgs,
    home-manager,
    mozilla,
    emacs,
    nur,
    # nix-direnv,
    # sops-nix,
    poetry2nix,
    pinnacle,
    pinnacle-config,
    clipcat,
    nix-doom,
    nixgl,
    cachyos-kernel,
    nix-index-database,
    ...
  } @ inputs: let
    hosts = ["cherry" "walnut" "magus" "yew"];
    homeUsers = ["cassandra"];
    nonNixosUsers = [
      {
        host = "nylld-ccomar1";
        os = "ubuntu";
        user = "ccomar";
      }
    ];
    system = "x86_64-linux";

    overlays = [
      cachyos-kernel.overlays.default
      mozilla.overlay
      emacs.overlay
      nur.overlays.default
      pinnacle.overlays.default
      nix-doom.overlays.default
      emacs.overlays.emacs
      nixgl.overlays.default
      (final: prev: {
        poetry2nix = poetry2nix.lib.mkPoetry2Nix {pkgs = prev;};
      })
      (final: prev: let
        iosevka-fonts = prev.callPackage ./packages/iosevka.nix {};
        helpers = prev.callPackage "${cachyos-kernel.outPath}/helpers.nix" {};
      in {
        inherit (prev.lixPackageSets.stable) nix-eval-jobs nix-fast-build colmena nixpkgs-review;
        inherit (iosevka-fonts) iosevka-nerd-font pyftfeatfreeze iosevka-custom;
        clipcat = clipcat.packages.${system}.clipcat;
        rofi-screenshot = prev.callPackage ./packages/rofi-screenshot.nix {};
        mkCachyPackageSet = kernel:
          helpers.kernelModuleLLVMOverride ((prev.linuxKernel.packagesFor kernel).extend (final': prev': {
            zfs_cachyos = prev.cachyosKernels.zfs-cachyos-lto.override {
              inherit kernel;
            };
          }));
      })
    ];

    pkgs = import nixpkgs {
      inherit system overlays;
      config = {
        allowUnfree = true;
      };
    };

    kernel = {
      pkgs,
      config,
      ...
    }: {
      # nixpkgs.overlays = [cachyos-kernel.overlays.default];
      boot = {
        kernelPackages = pkgs.lib.mkDefault (pkgs.mkCachyPackageSet pkgs.cachyosKernels.linux-cachyos-latest-lto);
        # bug fix for performance regression for zfs since 5.3
        kernelParams = ["init_on_alloc=0" "init_on_free=0"];
        zfs.package = config.boot.kernelPackages.zfs_cachyos;
      };
    };

    # sops-config = {
    #   sops.defaultSopsFile = ./.sops.yaml;
    #   sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    # };

    base-modules =
      [kernel ./modules ./system/base pinnacle.nixosModules.default nix-index-database.darwinModules.nix-index]
      ++ map (username: {
        environment.systemPackages = [
          pkgs.nushell
        ];
        users.users.${username} = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "networkmanager"
            "audio"
            "sound"
            "docker"
            "libvirtd"
            "transmission"
            "jackaudio"
            "adbusers"
          ];
          # shell = pkgs.nushell;
          hashedPasswordFile = "/etc/nixos/${username}.passwd";
          openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKzmQu/eY3tf06E6R3kVRv2XlA1GTmkYeIr9VlPRKRou ccomar@rclmp-ccomar1"];
        };
        nix.settings.trusted-users = [username];
      })
      homeUsers;
    user-module = username: {
      name = username;
      value = {
        imports = [
          (import ./user.nix {inherit username;})
        ];
      };
    };
    home-modules =
      pkgs.lib.foldl
      (m: user:
        m
        ++ [
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = [pinnacle.hmModules.default nix-doom.homeModule nix-index-database.homeModules.default];
              users = pkgs.lib.listToAttrs (map
                user-module
                [user]);
              extraSpecialArgs = {inherit pkgs user system pinnacle-config inputs;};
            };
          }
        ]) []
      homeUsers;

    iso = nixpkgs.lib.nixosSystem {
      inherit system pkgs;
      modules =
        map (username: {
          users.users.${username} = {
            initialHashedPassword = pkgs.lib.mkForce "";
            hashedPasswordFile = pkgs.lib.mkForce null;
          };
        })
        homeUsers
        ++ [
          ({modulesPath, ...}: {
            imports = [
              (modulesPath + "/installer/cd-dvd/installation-cd-base.nix")
              (modulesPath + "/profiles/base.nix")
              (modulesPath + "/profiles/all-hardware.nix")
            ];
          })
          {
            nix.extraOptions = ''
              system-features = gccarch-znver3 gccarch-znver4 gccarch-znver5 kvm nixos-test big-parallel benchmark
            '';
            console.font = "ter-v32b";
            networking.hostName = "balsa";
            networking.hostId = "604df261";
            services.openssh.enable = true;
            services.getty.autologinUser = pkgs.lib.mkForce "cassandra";
          }
          home-manager.nixosModules.home-manager
        ]
        ++ base-modules
        ++ home-modules;
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
                home-manager.nixosModules.home-manager
              ]
              ++ home-modules;
            specialArgs = {
              inherit system inputs nixpkgs;
            };
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

          modules = [pinnacle.hmModules.default nix-doom.homeModule (user-module userDef.user).value];
          extraSpecialArgs = {
            inherit pkgs system pinnacle-config inputs nixgl;
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
              extraSpecialArgs = {inherit pkgs user system pinnacle-config nixgl inputs;};
              modules = [pinnacle.hmModules.default nix-doom.homeModule (user-module user).value];
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
