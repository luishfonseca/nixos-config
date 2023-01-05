{ inputs, pkgs, lib, system, ... }: {
  mkPkgs = overlays:
    let args = { inherit system; config.allowUnfree = true; };
    in
    import inputs.nixpkgs (args // {
      overlays = [
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable args;
          latest = import inputs.nixpkgs-latest args;
        })
      ] ++ lib.attrValues overlays;
    });

  mkOverlays = overlaysDir: builtins.listToAttrs (map
    (m: {
      name = lib.removeSuffix ".nix" (builtins.baseNameOf m);
      value = import m;
    })
    (lib.my.listModulesRecursive overlaysDir));

  mkHost = name: { modulesDir, config, extraArgs, extraModules, ... }: lib.nixosSystem {
    inherit system pkgs lib;
    modules = [
      config
      { networking.hostName = lib.mkForce name; }
      { _module.args = extraArgs; }
    ] ++ lib.my.listModulesRecursive modulesDir ++ extraModules;
  };

  mkHosts = args: lib.mapAttrs
    (name: config: lib.my.mkHost name config)
    (lib.mapAttrs
      (name: _: {
        config = "${args.hostsDir}/${name}/configuration.nix";
      } // args)
      (lib.filterAttrs
        (p: _: !(lib.hasPrefix "_" p))
        (builtins.readDir args.hostsDir)));
}
