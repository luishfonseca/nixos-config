{ self, ... }@inputs: inputs.utils.lib.eachDefaultSystem (system:
  let
    pkgs = lib.my.mkPkgs ./overlays;
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
    packages = pkgs // { inherit lib nixosConfigurations; };
  })
