{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    utils.url = "github:numtide/flake-utils";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    nixos-anywhere.inputs.nixpkgs.follows = "nixpkgs";
    nixos-anywhere.inputs.disko.follows = "disko";
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
      diskoConfigurations = lib.lhf.mkDisks;
      modules = lib.lhf.rakeLeaves ./modules;
      profiles = lib.lhf.rakeLeaves ./profiles;
    in {
      inherit nixosConfigurations diskoConfigurations overlays;

      nixosModules = {
        inherit modules profiles;
      };

      packages =
        pkgs.lhf
        // {
          inherit lib;
        };

      devShells.default = pkgs.mkShell {
        packages = [
          inputs.nixos-anywhere.packages.${system}.nixos-anywhere
        ];
      };

      formatter = pkgs.alejandra;
    });
}
