{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    utils.url = "github:numtide/flake-utils";
  };

  outputs = {...} @ inputs:
    inputs.utils.lib.eachDefaultSystem (system: let
      lib = inputs.nixpkgs.lib.extend (self: super:
        import ./lib {
          inherit inputs system profiles modules pkgs nixosConfigurations;
          lib = self;
        });

      overlays = lib.lhf.mkOverlays ./overlays;
      pkgs = lib.lhf.mkPkgs overlays ./pkgs;
      nixosConfigurations = lib.lhf.mkHosts ./hosts;
      modules = lib.lhf.rakeLeaves ./modules;
      profiles = lib.lhf.rakeLeaves ./profiles;
    in {
      inherit nixosConfigurations overlays;

      nixosModules = {
        inherit modules profiles;
      };

      packages =
        pkgs.lhf
        // {
          inherit lib;
        };

      formatter = pkgs.alejandra;
    });
}
