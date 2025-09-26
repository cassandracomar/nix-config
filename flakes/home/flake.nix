{
  inputs.nix-config.url = "github:cassandracomar/nix-config";

  outputs = {nix-config, ...}: {
    inherit (nix-config) homeConfigurations;
  };
}
