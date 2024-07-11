{
  lib,
  inputs,
  ...
}: let
  /*
  *
  Synopsis: mkPkgs pkgsPath { system, overlays }

  Generate an attribute set representing Nix packages with custom overlays and packages.

  Inputs:
  - pkgsPath: The path to the directory containing custom Nix packages.
  - system: The target system platform (e.g., "x86_64-linux").
  - overlays: An attribute set of overlays to apply on top of the main Nixpkgs.

  Output Format:
  An attribute set representing Nix packages with custom overlays and packages.
  The function imports the main Nixpkgs and applies additional overlays defined in the `overlays` argument.
  The function adds a special overlay for the custom packages found in the `pkgsPath` directory.
  The function adds the `unstable` overlay with the packages from the `unstable` channel.

  *
  */
  mkPkgs = pkgsPath: {
    system,
    overlays,
  }: let
    argsPkgs = {
      inherit system;
      config.allowUnfree = true;
    };
  in
    import inputs.nixpkgs ({
        overlays =
          [
            (final: prev: {
              unstable = import inputs.unstable argsPkgs;
            })
            (final: prev: {
              lhf =
                prev.lib.mapAttrsRecursive
                (_: pkg: (prev.callPackage pkg {}))
                (lib.lhf.rakeLeaves pkgsPath);
            })
          ]
          ++ lib.attrValues overlays;
      }
      // argsPkgs);

  /*
  *
  Synopsis: mkOverlays overlaysPath

  Generate overlays for Nix expressions found in the specified directory.

  Inputs:
  - overlaysPath: The path to the directory containing Nix expressions.

  Output Format:
  An attribute set representing Nix overlays.
  The function recursively scans the `overlaysPath` directory for Nix expressions and imports each overlay.

  *
  */
  mkOverlays = overlaysPath:
    lib.mapAttrsRecursive
    (_: overlay: import overlay {inherit inputs;})
    (lib.lhf.rakeLeaves overlaysPath);

  /*
  *
  Synopsis: mkHost hostPath hostname { system, pkgs, profiles, modules, nixosConfigurations }

  Generate a NixOS system configuration for the specified hostname.

  Inputs:
  - hostPath: The path to the directory containing host-specific configurations.
  - hostname: The hostname for the target NixOS system.
  - system: The target system platform (e.g., "x86_64-linux").
  - pkgs: The final Nixpkgs.
  - profiles: The custom NixOS profiles.
  - modules: The custom NixOS modules.
  - nixosConfigurations: The NixOS system configurations.

  Output Format:
  A NixOS system configuration representing the specified hostname. The function generates
  a NixOS system configuration using the provided parameters and additional modules. It
  inherits attributes from `pkgs`, `lib`, `profiles`, `inputs` and `nixosConfigurations`.

  *
  */
  mkHost = hostPath: hostname: {
    system,
    pkgs,
    profiles,
    modules,
    nixosConfigurations,
  }:
    lib.nixosSystem {
      inherit system pkgs lib;
      specialArgs = {inherit profiles inputs nixosConfigurations;};
      modules =
        (lib.collect builtins.isPath modules)
        ++ [
          {networking.hostName = hostname;}
          "${hostPath}/${hostname}.nix"
        ];
    };

  /*
  *
  Synopsis: mkHosts hostsPath { system, pkgs, profiles, modules, nixosConfigurations }

  Generate a set of NixOS system configurations for the hosts defined in the specified directory.

  Inputs:
  - hostsPath: The path to the directory containing host-specific configurations.
  - system: The target system platform (e.g., "x86_64-linux").
  - pkgs: The final Nixpkgs.
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
  inherit mkHosts mkPkgs mkOverlays;
}
