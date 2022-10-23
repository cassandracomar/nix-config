{
  # pkg registries
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  # inputs.nixpkgs-master.url = "github:NixOS/nixpkgs/master";
  inputs.nixpkgs-master.url = "github:cassandracomar/nixpkgs";
  inputs.nixpkgs-optimized.url = "github:cassandracomar/nixpkgs/kernel-pin";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.xmonad-personal.url = "github:cassandracomar/dotxmonad";
  inputs.haskellNix.follows = "xmonad-personal/haskellNix";

  # overlays
  inputs.mozilla = { url = "github:mozilla/nixpkgs-mozilla"; };
  inputs.emacs.url = "github:nix-community/emacs-overlay";
  inputs.rust.url = "github:oxalica/rust-overlay";
  inputs.rust.inputs.nixpkgs.follows = "nixpkgs";
  inputs.rust.inputs.flake-utils.follows = "emacs/flake-utils";
  inputs.nur.url = "github:nix-community/NUR";

  # overrides via overlay
  inputs.nix-direnv.url = "github:cassandracomar/nix-direnv";
  inputs.nix-direnv.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    { self
    , nixpkgs
    , nixpkgs-master
    , nixpkgs-optimized
    , home-manager
    , xmonad-personal
    , haskellNix
    , mozilla
    , emacs
    , rust
    , nur
    , nix-direnv
    }@inputs:
    let
      hosts = [ "cherry" "walnut" "magus" "yew" ];
      homeUsers = [ "cassandra" ];
      system = "x86_64-linux";

      overlays = [
        mozilla.overlay
        emacs.overlay
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

          binutils_mold = pkgs.wrapBintoolsWith {
            bintools = pkgs.binutils-unwrapped.overrideAttrs (old: {
              postInstall = ''
                rm $out/bin/ld.gold
                rm $out/bin/ld.bfd
                ln -sf ${pkgs.mold}/bin/mold $out/bin/ld.bfd
              '';
            });
          };

          stdenv_mold = super.overrideCC super.stdenv (super.wrapCCWith rec {
            cc = super.gcc-unwrapped;
            bintools = pkgs.binutils_mold;
          });

        })
        (self: super:
          import ./packages/actualbudget/override.nix {
            pkgs = self;
            inherit system;
          })

        (self: super:
          import ./packages/drata.nix {
            inherit (self) lib;
            pkgs = self;
          })

        (self: super: {
          xmonad-personal = xmonad-personal.defaultPackage.${system};
        })
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

      base-modules = [ kernel ./modules ./system/base ];
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
              inherit system pkgs;
              modules = base-modules ++ [
                (import ./host.nix { inherit host; })
                home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users = pkgs.lib.listToAttrs (map
                    user-module
                    homeUsers);
                  home-manager.extraSpecialArgs = { inherit pkgs-master host haskellNix nixpkgs system; };
                  home-manager.sharedModules = [ ./modules/drata.nix ];
                }
              ];
              specialArgs = { inherit nixpkgs-optimized nixpkgs-master pkgs-master inputs; };
            };
          })
          hosts) // {
        inherit iso;
      };

    in
    {
      inherit nixosConfigurations;
      packages.${system} = pkgs;
      build = pkgs.lib.mapAttrs
        (name: value:
          value.config.system.build
        )
        nixosConfigurations;
    } //
    pkgs.lib.listToAttrs (map
      (host: {
        name = host;
        value = {
          homeConfigurations = pkgs.lib.listToAttrs (map
            (user: {
              name = user;
              value = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                modules = [ ./modules/drata.nix (user-module user).value ];
                extraSpecialArgs = { inherit pkgs-master host haskellNix nixpkgs system; };
              };
            })
            homeUsers);
        };
      })
      hosts);
}
