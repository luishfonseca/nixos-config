{
  inputs = {
    systems.url = "github:nix-systems/x86_64-linux"; # override this to use a different systems set

    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
    agenix.inputs.systems.follows = "systems";

    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    nixos-anywhere.inputs.nixpkgs.follows = "nixpkgs";
    nixos-anywhere.inputs.nixos-stable.follows = "nixpkgs";
    nixos-anywhere.inputs.disko.follows = "disko";
    nixos-anywhere.inputs.flake-parts.follows = "flake-parts";

    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.inputs.flake-compat.follows = "flake-compat";
    lanzaboote.inputs.flake-parts.follows = "flake-parts";
    lanzaboote.inputs.flake-utils.follows = "flake-utils";
    lanzaboote.inputs.pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";

    hardware.url = "github:NixOS/nixos-hardware/master";

    impermanence.url = "github:nix-community/impermanence";

    vscode-server.url = "github:nix-community/nixos-vscode-server";
    vscode-server.inputs.flake-utils.follows = "flake-utils";

    ### === Not used by me, but other inputs need it === ###
    flake-compat.url = "github:edolstra/flake-compat";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";

    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks-nix.inputs.nixpkgs-stable.follows = "nixpkgs";
    pre-commit-hooks-nix.inputs.flake-compat.follows = "flake-compat";
  };

  outputs = {self, ...} @ inputs: let
    pkgsConfig.allowUnfree = true;

    lib = inputs.nixpkgs.lib.extend (final: prev:
      import ./lib {
        inherit inputs;
        lib = final;
      });

    nixosModules = {
      modules = lib.lhf.rakeLeaves ./modules;
      profiles = lib.lhf.rakeLeaves ./profiles // {hardware = inputs.hardware.nixosModules;};
    };

    overlays = lib.lhf.mkOverlays ./pkgs {inherit pkgsConfig;};
    secrets = lib.lhf.mkSecrets ./secrets;
    publicKeys = import ./public-keys.nix;

    nixosConfigurations = lib.lhf.mkHosts ./hosts {
      inherit overlays pkgsConfig nixosConfigurations secrets publicKeys;
      inherit (nixosModules) modules profiles;
    };

    pkgs = lib.lhf.eachSystem (system:
      import inputs.nixpkgs {
        inherit system overlays;
        config = pkgsConfig;
      });

    packages = lib.lhf.eachSystem (system: pkgs.${system}.lhf);
    legacyPackages = lib.lhf.eachSystem (system: pkgs.${system}.lhf // {inherit lib;});

    devShells = lib.lhf.eachSystem (system: {
      default = with pkgs.${system};
        mkShell {
          packages = [
            age
            agenix
            lhf.deploy-anywhere
          ];
        };
    });

    formatter = lib.lhf.eachSystem (system: pkgs.${system}.alejandra);
  in {
    inherit lib nixosModules nixosConfigurations packages legacyPackages devShells formatter;
  };
}
