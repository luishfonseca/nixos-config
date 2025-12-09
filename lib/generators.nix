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
  The first part adds the `unstable` channel packages under the `unstable` attribute, configured by `pkgsConfig`.
  The second part adds the custom packages found in the `pkgsPath` directory under the `lhf` attribute.

  *
  */
  mkOverlay = pkgsPath: {pkgsConfig}: (final: prev: {
    unstable = import inputs.unstable {
      inherit (final.stdenv.hostPlatform) system;
      config = pkgsConfig;
    };
    lhf =
      final.lib.mapAttrsRecursive
      (_: pkg: (prev.callPackage pkg {}))
      (lib.lhf.rakeNixLeaves pkgsPath);
  });

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
  - secrets: Function that receives a hostname and returns a list of secrets.
  - publicKeys: List of public keys to generate the authorized_keys and known_hosts files.

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
    secrets,
    publicKeys,
  }:
    lib.nixosSystem {
      inherit lib;
      specialArgs = {
        inherit profiles inputs nixosConfigurations publicKeys;
        secrets = secrets hostname;
      };
      modules =
        (lib.collect builtins.isPath modules)
        ++ [
          {networking.hostName = hostname;}
          {
            nixpkgs = {
              inherit overlays;
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
  - secrets: Function that receives a hostname and returns a list of secrets.
  - publicKeys: List of public keys to generate the authorized_keys and known_hosts files.

  Output Format:
  An attribute set representing NixOS system configurations for the hosts
  found in the `hostsPath`. The function scans the `hostsPath` directory
  for host-specific Nix configurations and generates a set of NixOS
  system configurations for each host. The resulting attribute set maps
  hostnames to their corresponding NixOS system configurations.

  *
  */
  mkHosts = hostsPath: cfg:
    builtins.listToAttrs (
      builtins.map (hostname:
        lib.nameValuePair
        hostname
        (mkHost hostsPath hostname cfg))
      (builtins.map (path: lib.removeSuffix ".nix" path)
        (builtins.attrNames (builtins.readDir hostsPath)))
    );

  /*
  *
  Synopsis: mkSecrets secretsPath hostname

  Generate a list of secrets for the specified hostname.

  Inputs:
  - secretsPath: The path to the directory containing secrets.
  - hostname: The hostname for the target NixOS system.

  Output Format:
  An attribute set where each common or host specific entry under is mapped to the corresponding file path.

  Example secrets/ directory structure:
  ```
  -- secrets/
      -- common_secret
      -- your-host/
          -- password
  ```

  Example output for hostname `your-host`
  ```
  {
    common_secret.sopsFile = "/path/to/secrets/common_secret";
    password.sopsFile = "/path/to/secrets/your-host/password";
  }
  ```

  *
  */
  mkSecrets = secretsPath: hostname:
    builtins.mapAttrs (_: v: {sopsFile = v;})
    ((a: (builtins.removeAttrs a [hostname]) // a."${hostname}" or {})
      (lib.attrsets.filterAttrs (n: v: n == hostname || (! builtins.isAttrs v)) (lib.lhf.rakeAllLeaves secretsPath)));
in {
  inherit mkOverlay mkHosts mkSecrets;
}
