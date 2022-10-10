{
  description = "standalone home-manager configuration for configured users";

  inputs = {
    nix-config.url = "github:cassandracomar/nix-config";
    nixpkgs.follows = "nix-config/nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nix-config, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
    in
    {
      homeConfigurations = nix-config.home-configurations.${nixpkgs.builtins.getEnv "HOSTNAME"};
    };
}
