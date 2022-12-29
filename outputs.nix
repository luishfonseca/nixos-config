{ self, ... }@inputs:
let
  system = "x86_64-linux";
  overlays = lib.my.mkOverlays ./overlays;
  pkgs = lib.my.mkPkgs overlays;
  lib = inputs.nixpkgs.lib.extend (final: prev: import ./lib {
    inherit inputs pkgs system;
    lib = final;
  });

  # Primary user account
  user = "luis";

  nixosConfigurations = lib.my.mkHosts {
    modulesDir = ./modules;
    hostsDir = ./hosts;
    extraArgs = {
      inherit user inputs nixosConfigurations;
      root = ./.;
    };
    extraModules = [
      inputs.impermanence.nixosModules.impermanence
      inputs.home-manager.nixosModules.home-manager
    ];
  };
in
{
  inherit nixosConfigurations overlays;

  deploy.nodes = lib.mapAttrs
    (host: config: {
      hostname = host;
      fastConnection = true;
      profiles.system = {
        user = "root";
        sshUser = "root";
        path = inputs.deploy-rs.lib.${system}.activate.nixos config;
      };
    })
    nixosConfigurations;

  checks = lib.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;

  legacyPackages.${system} = pkgs // { inherit lib; };

  devShells.${system}.default = pkgs.mkShell {
    buildInputs = [
      inputs.deploy-rs.defaultPackage.${system}
      inputs.agenix.defaultPackage.${system}
    ];
  };
}
