{
  description = "system flake";

  inputs.nix-config.url = "github:cassandracomar/nix-config";

  outputs = { self, nix-config, ... }@inputs: {
    inherit (nix-config) nixosConfigurations;
  };
}
