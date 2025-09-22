# copy this file to /etc/nixos/flake.nix. then scripts/nixos-rebuild will use the latest pushed version of
# nix-config to manage the system configuration.
{
  description = "system flake";

  inputs.nix-config.url = "github:cassandracomar/nix-config";

  outputs = {
    self,
    nix-config,
    ...
  } @ inputs: {
    inherit (nix-config) nixosConfigurations;
  };
}
