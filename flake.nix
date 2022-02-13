{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixpkgs-master.url = "path:/home/cassandra/src/github.com/nixos/nixpkgs";

  outputs = { self, nixpkgs, nixpkgs-master }:
    let
      hosts = [ "cherry" "walnut" ];
      system = "x86_64-linux";
      pkgs = (import nixpkgs {
        inherit system;
        config.allowUnfree = true;

        config.packageOverides = pkgs:
          with pkgs; {

            steam = steam.override {
              nativeOnly = true;
              extraLibraries = [ pipewire.lib networkmanager ];
              extraPkgs = [ pipewire.lib ];
            };
            nur = import (builtins.fetchTarball
              "https://github.com/nix-community/NUR/archive/master.tar.gz") {
                inherit pkgs;
              };
          };
      });
      pkgs-master = (import nixpkgs-master {
        inherit system;
        config.allowUnfree = true;
      });

      kernel = ({pkgs, config, ...}: {
        boot.kernelPackages = pkgs-master.linuxKernel.packagesFor
          (pkgs-master.linuxKernel.kernels.linux_xanmod.override {
            stdenv = pkgs.clang12Stdenv;
            ignoreConfigErrors = true;
          });

        boot.kernel.sysctl."fs.inotify.max_user_instances" = 8192;
      });

      base-modules = [
        kernel
        ./system/base/default.nix
      ];

    in {
      nixosConfigurations = pkgs.lib.listToAttrs (map (host: {
        name = host;
        value = nixpkgs.lib.nixosSystem {
          inherit system pkgs;
          modules = base-modules ++ [ ./machines/${host}.nix ];
        };
      }) hosts);
    };
}
