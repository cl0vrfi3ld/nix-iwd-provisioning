{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # provisioning-module.url = ./.;
  };

  outputs =
    { self, nixpkgs }:
    {
      nixosModules = {
        nix-iwd-provisioning = ./provisioning.nix;
      };
      # homeManagerModule = { config }: { imports = [ ./provisioning.nix ]; };
    };
}
