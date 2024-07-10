{
  lib,
  pkgs,
  profiles,
  modules,
  inputs,
  nixosConfigurations,
  ...
}: let
  /*
  *
  Synopsis: mkPkgs overlays

  Generate an attribute set representing Nix packages with custom overlays and packages.

  Inputs:
  - overlays: An attribute set of overlays to apply on top of the main Nixpkgs.
  - pkgsDir: The path to the directory containing custom Nix packages.

  Output Format:
  An attribute set representing Nix packages with custom overlays and packages.
  The function imports the main Nixpkgs and applies additional overlays defined in the `overlays` argument.
  The function adds a special overlay for the custom packages found in the `pkgsDir` directory.
  The function adds the `unstable` overlay with the packages from the `unstable` channel.

  *
  */
  mkPkgs = overlays: pkgsDir: let
    argsPkgs = {
      system = "x86_64-linux";
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
                (lib.lhf.rakeLeaves pkgsDir);
            })
          ]
          ++ lib.attrValues overlays;
      }
      // argsPkgs);

  /*
  *
  Synopsis: mkOverlays overlaysDir

  Generate overlays for Nix expressions found in the specified directory.

  Inputs:
  - overlaysDir: The path to the directory containing Nix expressions.

  Output Format:
  An attribute set representing Nix overlays.
  The function recursively scans the `overlaysDir` directory for Nix expressions and imports each overlay.

  *
  */
  mkOverlays = overlaysDir:
    lib.mapAttrsRecursive
    (_: overlay: import overlay {inherit inputs;})
    (lib.lhf.rakeLeaves overlaysDir);

  /*
  *
  Synopsis: mkHost hostname { system, hostPath }

  Generate a NixOS system configuration for the specified hostname.

  Inputs:
  - hostname: The hostname for the target NixOS system.
  - system: The target system platform (e.g., "x86_64-linux").
  - hostPath: The path to the directory containing host-specific Nix configurations.

  Output Format:
  A NixOS system configuration representing the specified hostname. The function generates
  a NixOS system configuration using the provided parameters and additional modules. It
  inherits attributes from `pkgs`, `lib`, `profiles`, `inputs` and `nixosConfigurations`.

  *
  */
  mkHost = hostname: {
    system,
    hostPath,
  }:
    lib.nixosSystem {
      inherit system pkgs lib;
      specialArgs = {inherit profiles inputs nixosConfigurations;};
      modules =
        (lib.collect builtins.isPath modules)
        ++ [
          {networking.hostName = hostname;}
          hostPath
        ];
    };

  /*
  *
  Synopsis: mkHosts hostsDir

  Generate a set of NixOS system configurations for the hosts defined in the specified directory.

  Inputs:
  - hostsDir: The path to the directory containing host-specific configurations.

  Output Format:
  An attribute set representing NixOS system configurations for the hosts
  found in the `hostsDir`. The function scans the `hostsDir` directory
  for host-specific Nix configurations and generates a set of NixOS
  system configurations for each host. The resulting attribute set maps
  hostnames to their corresponding NixOS system configurations.

  *
  */
  mkHosts = hostsDir: (lib.mapAttrs
    (host: cfg: mkHost host cfg)
    (lib.mapAttrs
      (host: hostPath: {
        inherit hostPath;
        system = "x86_64-linux";
      })
      (lib.attrsets.mapAttrs'
        (path: _: lib.attrsets.nameValuePair (lib.removeSuffix ".nix" path) "${hostsDir}/${path}")
        (builtins.readDir hostsDir))));

  /*
  *
  Synopsis: mkSecrets secretsDir

  Generate a set of secrets to be used by agenix.

  Inputs:
  - secretsDir: The path to the directory containing secrets.

  Output Format:
  An attribute set representing secrets.
  The function scans the `secretsDir` directory recursively for secrets and
  generates a set of secrets for each host.
  The resulting attribute set maps paths to their corresponding secret file.

  Example input:
  ```
  ./secrets/secrets.nix
  ./secrets/key1.age
  ./secrets/key2.nix
  ./secrets/host-keys/key3.age
  ```

  Example output:
  {
    "key1".file = ./secrets/key1.age;
    "key2".file = ./secrets/key2.age;
    "host-keys/key3".file = ./secrets/host-keys/key3.age;
  }

  *
  */
  mkSecrets = secretsDir:
    builtins.listToAttrs (builtins.map
      (file: let
        name = lib.removePrefix (toString secretsDir + "/") (toString file);
      in {
        inherit name;
        value = {inherit file;};
      })
      (builtins.filter (p: lib.hasSuffix ".age" p) (lib.filesystem.listFilesRecursive secretsDir)));
in {
  inherit mkHosts mkPkgs mkOverlays mkSecrets;
}
