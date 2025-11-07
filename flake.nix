{
  description = "A very basic flake";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # provisioning-module.url = ./.;
  };

  outputs =
    { self }:
    {
      nixosModules = {
        iwd-provisioning = ./modules/provisioning.nix;
        iwd-eduroam = ./modules/eduroam.nix;
      };
      # homeManagerModule = { config }: { imports = [ ./provisioning.nix ]; };
    };
}
