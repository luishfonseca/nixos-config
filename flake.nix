{
  inputs = {
    systems.url = "github:nix-systems/x86_64-linux"; # override this to use a different systems set

    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    impermanence.url = "github:nix-community/impermanence";

    nix-colors = {
      url = "github:misterio77/nix-colors";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixos-stable.follows = "nixpkgs";
        disko.follows = "disko";
        flake-parts.follows = "flake-parts";
        nix-vm-test.follows = "nix-vm-test";
        nixos-images.follows = "nixos-images";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
      };
    };

    hardware.url = "github:NixOS/nixos-hardware/master";

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        gitignore.follows = "gitignore";
      };
    };

    ### === Not used by me, but other inputs need it === ###
    flake-compat.url = "github:edolstra/flake-compat";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    nix-vm-test = {
      url = "github:Mic92/nix-vm-test";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-images = {
      url = "github:nix-community/nixos-images";
      inputs = {
        nixos-stable.follows = "nixpkgs";
        nixos-unstable.follows = "unstable";
      };
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: let
    pkgsConfig.allowUnfree = true;

    lib = inputs.nixpkgs.lib.extend (final: _:
      import ./lib {
        inherit inputs;
        lib = final;
      });

    nixosModules = {
      modules = lib.lhf.rakeNixLeaves ./modules;
      profiles = lib.lhf.rakeNixLeaves ./profiles // {hardware = inputs.hardware.nixosModules;};
    };

    overlays = [
      (lib.lhf.mkOverlay ./pkgs {inherit pkgsConfig;})
      (final: _: {inherit (inputs.nixos-anywhere.packages.${final.system}) nixos-anywhere;})
      inputs.rust-overlay.overlays.default
    ];

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

    checks = lib.lhf.eachSystem (system: {
      pre-commit-check = inputs.pre-commit-hooks-nix.lib.${system}.run {
        src = ./.;
        hooks = {
          # Nix
          alejandra.enable = true;
          flake-checker.enable = true;
          statix.enable = true;
          deadnix.enable = true;

          # Shell
          shellcheck.enable = true;
          shfmt.enable = true;
        };
      };
    });

    devShells = lib.lhf.eachSystem (system: {
      default = with pkgs.${system};
        mkShell {
          inherit (checks.${system}) pre-commit-check;
          packages =
            [
              disko
              sops
              lhf.prepare-secrets
              lhf.deploy-anywhere
            ]
            ++ checks.${system}.pre-commit-check.enabledPackages;
        };
    });

    formatter = lib.lhf.eachSystem (system: pkgs.${system}.alejandra);
  in {
    inherit lib nixosModules nixosConfigurations packages legacyPackages checks devShells formatter;
  };
}
