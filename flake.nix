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

  outputs = {self, ...} @ inputs: let
    lib = inputs.nixpkgs.lib.extend (self: super:
      import ./lib {
        inherit inputs;
        lib = self;
      });

    modules = lib.lhf.rakeLeaves ./modules;
    profiles = lib.lhf.rakeLeaves ./profiles;
    overlays = lib.lhf.mkOverlays ./overlays;
  in
    inputs.utils.lib.eachDefaultSystem (system: let
      pkgs = lib.lhf.mkPkgs ./pkgs {inherit system overlays;};
      nixosConfigurations = lib.lhf.mkHosts ./hosts {inherit system pkgs profiles modules nixosConfigurations;};
    in {
      packages =
        pkgs.lhf
        // {
          inherit lib nixosConfigurations;
        };

      devShells.default = pkgs.mkShell {
        packages = [
          inputs.nixos-anywhere.packages.${system}.nixos-anywhere
        ];
      };

      formatter = pkgs.alejandra;
    })
    // {
      inherit overlays;
      nixosModules = {inherit modules profiles;};
    };
}
