{
  # pkg registries
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nixpkgs-master.url =
    "path:/home/cassandra/src/github.com/nixos/nixpkgs";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.xmonad-personal.url = "path:/home/cassandra/.xmonad";

  # overlays
  inputs.mozilla = { url = "github:mozilla/nixpkgs-mozilla"; };
  inputs.emacs.url = "github:nix-community/emacs-overlay";
  inputs.rust.url = "github:oxalica/rust-overlay";
  inputs.nur.url = "github:nix-community/NUR";

  outputs = { self, nixpkgs, nixpkgs-master, home-manager, xmonad-personal
    , mozilla, emacs, rust, nur }@inputs:
    let
      hosts = [ "cherry" "walnut" ];
      homeUsers = [ "cassandra" ];
      system = "x86_64-linux";

      overlays = [
        mozilla.overlay
        emacs.overlay
        rust.overlay
        nur.overlay
        (self: super: {
          calibre = super.calibre.overrideAttrs (oldAttrs: {
            # We want to have pycryptodome around in order to support DeDRM
            nativeBuildInputs = oldAttrs.nativeBuildInputs
              ++ [ self.python3Packages.pycryptodome ];
          });
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
          (pkgs-master.linuxKernel.kernels.linux_xanmod.override {
            stdenv = pkgs.clang12Stdenv;
            ignoreConfigErrors = true;
          });

        boot.kernel.sysctl."fs.inotify.max_user_instances" = 8192;
      });

      base-modules = [ kernel ./system/base ];

    in {
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
            }
          ];
          specialArgs = { inherit pkgs-master inputs; };
        };
      }) hosts);

      # homeConfigurations = pkgs.lib.listToAttrs (map (username: {
      #   name = username;
      #   value = home-manager.lib.homeManagerConfiguration {
      #     # Specify the path to your home configuration here
      #     configuration = import ./user.nix { inherit username; };

      #     inherit system username pkgs;
      #     homeDirectory = "/home/${username}";
      #     # Update the state version as needed.
      #     # See the changelog here:
      #     # https://nix-community.github.io/home-manager/release-notes.html#sec-release-21.05
      #     stateVersion = "21.11";

      #     # Optionally use extraSpecialArgs
      #     # to pass through arguments to home.nix
      #     extraSpecialArgs = { inherit pkgs-master inputs username; };
      #   };
      # }) homeUsers);
    };
}
