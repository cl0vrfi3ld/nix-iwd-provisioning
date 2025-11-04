{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # provisioning-module.url = ./provisioning.nix;
  };

  outputs =
    { self, nixpkgs}:
    {

      nixosModules.nix-iwd-provisioning = { config }: { imports = [ ./provisioning.nix ]; };
      # homeManagerModule = { config }: { imports = [ ./provisioning.nix ]; };
    };
}
