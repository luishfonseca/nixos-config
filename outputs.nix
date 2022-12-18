{ self, ... }@inputs: inputs.utils.lib.eachDefaultSystem (system:
  let
    pkgs = lib.my.mkPkgs ./overlays;
    lib = inputs.nixpkgs.lib.extend (final: prev: import ./lib {
      inherit inputs pkgs system;
      lib = final;
    });

    # Primary user account
    user = "luis";
  in
  {
    packages = pkgs // {
      nixosConfigurations = lib.my.mkHosts {
        modulesDir = ./modules;
        hostsDir = ./hosts;
        extraArgs = {
          inherit user inputs;
          root = ./.;
        };
        extraModules = [
          inputs.impermanence.nixosModules.impermanence
          inputs.home-manager.nixosModules.home-manager
        ];
      };
    };
  })
