{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    utils.url = "github:numtide/flake-utils";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

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

    nixosModules = {
      modules = lib.lhf.rakeLeaves ./modules;
      profiles = lib.lhf.rakeLeaves ./profiles;
    };
  in
    inputs.utils.lib.eachDefaultSystem (system: let
      pkgs = lib.lhf.mkPkgs ./pkgs system;
      nixosConfigurations = lib.lhf.mkHosts ./hosts {
        inherit system pkgs nixosConfigurations;
        inherit (nixosModules) modules profiles;
      };
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
    // {inherit nixosModules;};
}
