# flake.nix
{
  description = "custom iso with zfs, etc.";
  inputs.nix-config.url = "path:..";
  inputs.nixos.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { self, nixos, nix-config }: {

    nixosConfigurations = let
      # Shared base configuration.
      myBase = {
        system = "x86_64-linux";
        modules = [
          # Common system modules...
        ];
      };
      hosts = nix-config.nixosConfigurations;
    in hosts // {
      iso = nixos.lib.nixosSystem {
        inherit (myBase) system;
        modules = myBase.modules ++ [
          "${nixos}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
          "${nixos}/nixos/modules/installer/cd-dvd/channel.nix"
          ./installer.nix
        ];
      };
    };
  };
}
