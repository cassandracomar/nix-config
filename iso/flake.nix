# flake.nix
{
  description = "custom iso with zfs, etc.";
  inputs.nixos.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { self, nixos }: {

    nixosConfigurations = let
      # Shared base configuration.
      myBase = {
        system = "x86_64-linux";
        modules = [
          # Common system modules...
        ];
      };
    in {
      iso = nixos.lib.nixosSystem {
        inherit (myBase) system;
        modules = myBase.modules ++ [
          "${nixos}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
          "${nixos}/nixos/modules/installer/cd-dvd/channel.nix"
          ./installer.nix
        ];
      };
      install = nixos.lib.nixosSystem {
        inherit (myBase) system;
        modules = myBase.modules ++ [{ imports = [ ../configuration.nix ]; }];
      };
    };
  };
}
