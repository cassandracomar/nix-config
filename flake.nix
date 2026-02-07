{
  # pkg registries
  inputs.nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
  inputs.flake-input-patcher.url = "github:jfly/flake-input-patcher";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  inputs.cachyos-kernel.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nix-index.url = "github:nix-community/nix-index";
  inputs.nix-index.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nix-index-database.url = "github:nix-community/nix-index-database";
  inputs.nix-index-database.inputs.nixpkgs.follows = "";

  # overlays
  inputs.emacs.url = "github:nix-community/emacs-overlay";
  inputs.emacs.inputs.nixpkgs.follows = "";
  inputs.emacs.inputs.nixpkgs-stable.follows = "";
  inputs.nur.url = "github:nix-community/NUR";
  inputs.nur.inputs.nixpkgs.follows = "nixpkgs";

  inputs.poetry2nix.url = "github:nix-community/poetry2nix";
  inputs.poetry2nix.inputs.nixpkgs.follows = "";
  inputs.pinnacle.url = "github:pinnacle-comp/pinnacle";
  inputs.pinnacle.inputs.nixpkgs.follows = "";
  inputs.pinnacle-config.url = "github:cassandracomar/pinnacle-config";
  inputs.pinnacle-config.inputs.pinnacle.follows = "pinnacle";
  inputs.pinnacle-config.inputs.nixpkgs.follows = "";
  inputs.clipcat.url = "github:xrelkd/clipcat";
  inputs.clipcat.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-doom.url = "github:marienz/nix-doom-emacs-unstraightened";
  inputs.nix-doom.inputs.nixpkgs.follows = "";
  inputs.nix-doom.inputs.emacs-overlay.follows = "emacs";
  inputs.doom-config.url = "github:cassandracomar/doom-config";
  inputs.doom-config.flake = false;

  inputs.nixgl.url = "github:nix-community/nixGL";
  inputs.nixgl.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nix-output-monitor.url = "github:maralorn/nix-output-monitor";
  inputs.nix-output-monitor.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nh.url = "github:nix-community/nh";
  inputs.nh.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {
    nixpkgs,
    flake-input-patcher,
    home-manager,
    emacs,
    nur,
    poetry2nix,
    pinnacle,
    pinnacle-config,
    clipcat,
    nix-doom,
    nixgl,
    cachyos-kernel,
    nix-output-monitor,
    nh,
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
    patcher = flake-input-patcher.lib.${system};
    inputs' = patcher.patch inputs {
      nix-index-database.patches = [
        (patcher.fetchpatch {
          url = "https://patch-diff.githubusercontent.com/raw/nix-community/nix-index-database/pull/164.patch";
          sha256 = "sha256-cELe2shVKfaYquV/I24D0uAXx3wjCIrV/amK1LAwQEA=";
        })
      ];
    };

    overlays = [
      cachyos-kernel.overlays.default
      emacs.overlay
      nur.overlays.default
      pinnacle.overlays.default
      nix-doom.overlays.default
      emacs.overlays.emacs
      nixgl.overlays.default
      nh.overlays.default
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
        nix-output-monitor = nix-output-monitor.packages.${system}.default;
      })
    ];

    pkgs = import nixpkgs {
      inherit system overlays;
      config = {
        allowUnfree = true;
        nvidia.acceptLicense = true;
      };
    };

    kernel = {
      pkgs,
      config,
      ...
    }: {
      # nixpkgs.overlays = [cachyos-kernel.overlays.default];
      boot = {
        # kernelPackages = pkgs.lib.mkDefault (pkgs.mkCachyPackageSet pkgs.cachyosKernels.linux-cachyos-latest-lto);
        # bug fix for performance regression for zfs since 5.3
        kernelParams = ["init_on_alloc=0" "init_on_free=0"];
        zfs.modulePackage = config.boot.kernelPackages.zfs_cachyos;
      };
    };

    # sops-config = {
    #   sops.defaultSopsFile = ./.sops.yaml;
    #   sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    # };

    base-modules =
      [
        kernel
        ./modules
        ./system/base
        pinnacle.nixosModules.default
        inputs'.nix-index-database.nixosModules.default
        {programs.nix-index-database.comma.enable = true;}
      ]
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
          inputs'.nix-index-database.homeModules.default
          (import ./user.nix {inherit username;})
        ];
        programs.nix-index-database.comma.enable = true;
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
              sharedModules = [
                pinnacle.hmModules.default
                nix-doom.homeModule
              ];
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

    formatter.${system} = pkgs.alejandra;
    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
  };
}
