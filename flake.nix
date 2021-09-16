# flake.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# The core of my dotfiles. A good starting point.

{
  description = "Dotfiles for a comprehensive single user system.";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    latest = { url = "github:nixos/nixpkgs/master"; };
    hardware = { url = "github:nixos/nixos-hardware/master"; };
    impermanence = { url = "github:nix-community/impermanence/master"; };
    home = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, ... }:
    let
      inherit (builtins) listToAttrs attrValues attrNames readDir;
      inherit (inputs.nixpkgs) lib;
      inherit (lib) removeSuffix;

      system = "x86_64-linux";
      user = "luis";

      pkgs = (import inputs.nixpkgs) {
        inherit system;
        config.allowUnfree = true;
        overlays = attrValues self.overlays;
      };

      mkOverlays = dir:
        listToAttrs (map (name: {
          name = removeSuffix ".nix" name;
          value = import (dir + "/${name}");
        }) (attrNames (readDir dir)));

      mkHosts = dir:
        listToAttrs (map (hostName: {
          name = hostName;
          value = inputs.nixpkgs.lib.nixosSystem {
            inherit system pkgs;
            extraArgs = { inherit hostName user; };
            modules = [
              dir
              (dir + "/${hostName}/configuration.nix")
              inputs.home.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = { inherit hostName user; };
                home-manager.users.${user} =
                  import (dir + "/${hostName}/home.nix");
              }
              inputs.impermanence.nixosModules.impermanence
            ] ++ {
              sirius = with inputs.hardware.nixosModules; [
                common-pc
                common-gpu-amd
                common-cpu-amd
              ];
              altair = with inputs.hardware.nixosModules;
                [ lenovo-thinkpad-t440p ];
            }.hostName or [ ];
          };
        }) (attrNames (readDir dir)));

    in {

      overlays = mkOverlays ./overlays // {
        latest = final: prev: {
          latest = import inputs.latest {
            inherit system;
            config.allowUnfree = true;
          };
        };
      };

      nixosConfigurations = mkHosts ./hosts;
    };
}
