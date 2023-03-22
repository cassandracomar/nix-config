{
  # pkg registries
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  # inputs.nixpkgs-master.url = "github:NixOS/nixpkgs/master";
  inputs.nixpkgs-master.url = "github:cassandracomar/nixpkgs";
  inputs.nixpkgs-optimized.url = "github:cassandracomar/nixpkgs/kernel-pin";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.xmonad-personal.url = "github:cassandracomar/dotxmonad";

  # encryption
  inputs.sops-nix.url = "github:Mic92/sops-nix";

  # overlays
  inputs.mozilla = { url = "github:mozilla/nixpkgs-mozilla"; };
  inputs.emacs.url = "github:nix-community/emacs-overlay";
  inputs.emacs-src.url = "github:emacs-mirror/emacs/emacs-29";
  inputs.emacs-src.flake = false;
  inputs.rust.url = "github:oxalica/rust-overlay";
  inputs.rust.inputs.nixpkgs.follows = "nixpkgs";
  inputs.rust.inputs.flake-utils.follows = "emacs/flake-utils";
  inputs.nur.url = "github:nix-community/NUR";
  inputs.openconnect = {
    url = "github:vlaci/openconnect-sso";
    flake = false;
  };

  # overrides via overlay
  inputs.nix-direnv.url = "github:nix-community/nix-direnv";
  inputs.nix-direnv.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    { self
    , nixpkgs
    , nixpkgs-master
    , nixpkgs-optimized
    , home-manager
    , xmonad-personal
    , sops-nix
    , mozilla
    , emacs
    , emacs-src
    , rust
    , nur
    , nix-direnv
    , openconnect
    }@inputs:
    let
      hosts = [ "cherry" "walnut" "magus" "yew" ];
      homeUsers = [ "cassandra" ];
      nonNixosUsers = [{
        host = "rnwld-ccomar1";
        os = "ubuntu";
        user = "ccomar";
      }];
      system = "x86_64-linux";

      overlays = [
        mozilla.overlay
        emacs.overlay
        (final: prev: {
          emacsPgtk = prev.emacsGit.overrideAttrs
            (old: {
              name = "emacs-unstable";
              version = inputs.emacs-src.shortRev;
              src = inputs.emacs-src;
            });
        })
        rust.overlays.default
        nur.overlay
        (self: super: {
          calibre = super.calibre.overrideAttrs (oldAttrs: {
            # We want to have pycryptodome around in order to support DeDRM
            nativeBuildInputs = oldAttrs.nativeBuildInputs
              ++ [ self.python3Packages.pycryptodome ];
          });

          nix-direnv = nix-direnv.defaultPackage.${system};
          vcluster =
            import ./packages/vcluster.nix { inherit (self) fetchurl stdenv; };

          iosevkaCustom = self.iosevka.override {
            privateBuildPlan = {
              family = "Iosevka Custom";
              design =
                [ "ligset-haskell" "ligset-clike" "ligset-javascript" "ligset-swift" ];

            };
            set = "custom";
          };
        })
        (self: super:
          import ./packages/actualbudget/override.nix {
            pkgs = self;
            inherit system;
          }
        )

        (self: super:
          let
            kpkgs = nixpkgs-optimized.legacyPackages.${system};
          in
          {
            CoreFreq = pkgs.callPackage ./packages/corefreq.nix {
              kernel = kpkgs.linux_xanmod_tt.override {
                ignoreConfigErrors = true;
              };
            };
          })

        (self: super: {
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
              extraLibraries = [ pipewire.lib networkmanager ];
              extraPkgs = [ pipewire.lib ];
            };
          };
      };
      pkgs-master = import nixpkgs-master {
        inherit system;
        config.allowUnfree = true;
      };

      kernel = ({ pkgs, config, ... }: {
        boot.kernelPackages = pkgs.lib.mkDefault (pkgs-master.linuxKernel.packagesFor
          (pkgs-master.linuxKernel.kernels.linux_xanmod_tt.override {
            stdenv = pkgs.gcc12Stdenv;
          }));
        # bug fix for performance regression for zfs since 5.3
        boot.kernelParams = [ "init_on_alloc=0" "init_on_free=0" ];

        boot.kernel.sysctl."fs.inotify.max_user_instances" = 8192;
      });

      base-modules = [ kernel ./modules ./system/base sops-nix.nixosModules.sops ];
      user-module = (username: {
        name = username;
        value = {
          imports = [
            (import ./user.nix { inherit username; })
            {
              manual.manpages.enable = false;
              home.packages =
                [
                  xmonad-personal.defaultPackage.${system}
                ];
            }
          ];
        };
      });

      iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        pkgs = import nixpkgs-master {
          inherit system;
          config.allowUnfree = true;
          config.allowBroken = true;
        };
        modules = [
          "${nixpkgs-master}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
          "${nixpkgs-master}/nixos/modules/installer/cd-dvd/channel.nix"
          ./iso/installer.nix
        ];
      };

      nixosConfigurations = pkgs.lib.listToAttrs
        (map
          (host: {
            name = host;
            value = nixpkgs.lib.nixosSystem {
              inherit pkgs;
              modules = base-modules ++ [
                (import ./host.nix { inherit host; })
              ] ++ (pkgs.lib.foldl (m: user:
                m ++ [home-manager.nixosModules.home-manager
                {
                  inherit pkgs;
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users = pkgs.lib.listToAttrs (map
                    user-module
                    [user]);
                  home-manager.extraSpecialArgs = { inherit pkgs-master host nixpkgs system; };
                }]) [] homeUsers);
              specialArgs = { inherit nixpkgs-optimized nixpkgs-master pkgs-master inputs; };
            };
          })
          hosts) // {
        inherit iso;
      };

      nonNixosHomeConfigs = pkgs.lib.listToAttrs (map
        (userDef: {
          name = "${userDef.user}@${userDef.host}";
          value = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            modules = [ (user-module userDef.user).value ];
            extraSpecialArgs = {
              inherit nixpkgs-master pkgs-master inputs;
              inherit (userDef) user os host;
            };
          };
        })
        nonNixosUsers);

    in
    {
      inherit nixosConfigurations;
      packages.${system} = pkgs;
      build = pkgs.lib.mapAttrs
        (name: value:
          value.config.system.build
        )
        nixosConfigurations;

      homeConfigurations = pkgs.lib.foldl
        (homeConfig: host:
          homeConfig // pkgs.lib.listToAttrs
            (map
              (user: {
                name = "${user}@${host}";
                value = home-manager.lib.homeManagerConfiguration {
                  inherit pkgs;
                  modules = [ (user-module user).value ];
                  extraSpecialArgs = { inherit pkgs-master host nixpkgs system user; };
                };
              })
              homeUsers))
        { }
        hosts // nonNixosHomeConfigs;
    };
}
