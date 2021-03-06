{
  # pkg registries
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nixpkgs-master.url = "github:cassandracomar/nixpkgs";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.xmonad-personal.url = "github:cassandracomar/dotxmonad";

  # overlays
  inputs.mozilla = { url = "github:mozilla/nixpkgs-mozilla"; };
  inputs.emacs.url = "github:nix-community/emacs-overlay";
  inputs.rust.url = "github:oxalica/rust-overlay";
  inputs.nur.url = "github:nix-community/NUR";

  # overrides via overlay
  inputs.nix-direnv.url = "github:nix-community/nix-direnv";
  inputs.nix-direnv.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, nixpkgs-master, home-manager, xmonad-personal
    , mozilla, emacs, rust, nur, nix-direnv }@inputs:
    let
      hosts = [ "cherry" "walnut" ];
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
      ];

      pkgs = (import nixpkgs {
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
      });
      pkgs-master = (import nixpkgs-master {
        inherit system;
        config.allowUnfree = true;
      });

      kernel = ({ pkgs, config, ... }: {
        boot.kernelPackages = pkgs-master.linuxKernel.packagesFor
          (pkgs-master.linuxKernel.kernels.linux_xanmod_tt.override {
            stdenv = pkgs.clang12Stdenv;
            ignoreConfigErrors = true;
          });

        boot.kernel.sysctl."fs.inotify.max_user_instances" = 8192;
      });

      base-modules = [ kernel ./modules ./system/base ];

    in {
      packages.${system} = pkgs;
      nixosConfigurations = pkgs.lib.listToAttrs (map (host: {
        name = host;
        value = nixpkgs.lib.nixosSystem {
          inherit system pkgs;
          modules = base-modules ++ [
            (import ./host.nix { inherit host; })
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users = pkgs.lib.listToAttrs (map (username: {
                name = username;
                value = {
                  imports = [
                    (import ./user.nix { inherit username; })
                    ({ pkgs, ... }: {
                      home.packages =
                        [ xmonad-personal.defaultPackage.${system} ];
                    })
                  ];
                };
              }) homeUsers);
              home-manager.extraSpecialArgs = { inherit pkgs-master host; };
              home-manager.sharedModules = [ ./modules/drata.nix ];
            }
          ];
          specialArgs = { inherit pkgs-master inputs; };
        };
      }) hosts) // {
        iso = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
            ./iso/installer.nix
          ];
        };
      };
    };
}
