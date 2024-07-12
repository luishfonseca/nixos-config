{
  lib,
  inputs,
  ...
}: let
  /*
  *
  Synopsis: mkOverlay pkgsPath { pkgsConfig }

  Generate an overlay with unstable and custom packages.

  Inputs:
  - pkgsPath: The path to the directory containing custom Nix packages.
  - pkgsConfig: The Nixpkgs configuration.

  Output Format:
  A list of overlays with unstable and custom packages.
  The first overlay adds the `unstable` channel packages under the `unstable` attribute, configured by `pkgsConfig`.
  The second overlay adds the custom packages found in the `pkgsPath` directory under the `lhf` attribute.

  *
  */
  mkOverlays = pkgsPath: {pkgsConfig}: [
    (final: prev: {
      unstable = import inputs.unstable ({
          inherit (final) system;
        }
        // pkgsConfig);
    })
    (final: prev: {
      lhf =
        prev.lib.mapAttrsRecursive
        (_: pkg: (prev.callPackage pkg {}))
        (lib.lhf.rakeLeaves pkgsPath);
    })
  ];

  /*
  *
  Synopsis: mkHost hostPath hostname { overlays, pkgsConfig, profiles, modules, nixosConfigurations }

  Generate a NixOS system configuration for the specified hostname.

  Inputs:
  - hostPath: The path to the directory containing host-specific configurations.
  - hostname: The hostname for the target NixOS system.
  - overlays: The custom NixOS overlays to be applied to Nixpkgs.
  - pkgsConfig: The Nixpkgs configuration.
  - profiles: The custom NixOS profiles.
  - modules: The custom NixOS modules.
  - nixosConfigurations: The NixOS system configurations.

  Output Format:
  A NixOS system configuration representing the specified hostname. The function generates
  a NixOS system configuration using the provided parameters and additional modules. It
  inherits attributes from `overlays`, `lib`, `profiles`, `inputs` and `nixosConfigurations`.

  *
  */
  mkHost = hostPath: hostname: {
    overlays,
    pkgsConfig,
    profiles,
    modules,
    nixosConfigurations,
  }:
    lib.nixosSystem {
      inherit lib;
      specialArgs = {inherit profiles inputs nixosConfigurations;};
      modules =
        (lib.collect builtins.isPath modules)
        ++ [
          {networking.hostName = hostname;}
          {
            nixpkgs = {
              overlays = overlays;
              config = pkgsConfig;
            };
          }
          "${hostPath}/${hostname}.nix"
        ];
    };

  /*
  *
  Synopsis: mkHosts hostsPath { overlays, pkgsConfig, profiles, modules, nixosConfigurations }

  Generate a set of NixOS system configurations for the hosts defined in the specified directory.

  Inputs:
  - hostsPath: The path to the directory containing host-specific configurations.
  - overlays: The custom NixOS overlays to be applied to Nixpkgs.
  - pkgsConfig: The Nixpkgs configuration.
  - profiles: The custom NixOS profiles.
  - modules: The custom NixOS modules.
  - nixosConfigurations: The NixOS system configurations.

  Output Format:
  An attribute set representing NixOS system configurations for the hosts
  found in the `hostsPath`. The function scans the `hostsPath` directory
  for host-specific Nix configurations and generates a set of NixOS
  system configurations for each host. The resulting attribute set maps
  hostnames to their corresponding NixOS system configurations.

  *
  */
  mkHosts = hostsPath: {...} @ cfg:
    builtins.listToAttrs (
      builtins.map
      (hostname: lib.nameValuePair hostname (mkHost hostsPath hostname cfg))
      (builtins.map (path: lib.removeSuffix ".nix" path)
        (builtins.attrNames (builtins.readDir hostsPath)))
    );
in {
  inherit mkOverlays mkHosts;
}
