{ inputs, pkgs, lib, system, ... }: {
  mkPkgs = overlays:
    let args = { inherit system; config.allowUnfree = true; };
    in
    import inputs.nixpkgs (args // {
      overlays = [
        (final: prev: { unstable = import inputs.nixpkgs-unstable args; })
      ] ++ lib.attrValues overlays;
    });

  mkOverlays = overlaysDir: builtins.listToAttrs (map
    (m: {
      name = lib.removeSuffix ".nix" (builtins.baseNameOf m);
      value = import m;
    })
    (lib.my.listModulesRecursive overlaysDir));

  mkProfiles = profilesDir:
    (map
      (p: ({ config, pkgs, lib, inputs, ... } @ args: {
        config = lib.mkIf
          (builtins.elem (lib.removeSuffix ".nix" (builtins.baseNameOf p)) config.profiles)
          (import p args);
      }))
      (lib.my.listModulesRecursive profilesDir)
    ) ++ [
      ({ options, lib, ... }: {
        options.profiles = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      })
    ];

  mkHost = name: { modulesDir, profilesDir, config, extraArgs, extraModules, ... }: lib.nixosSystem {
    inherit system pkgs lib;
    modules = [
      config
      { networking.hostName = lib.mkForce name; }
      { _module.args = extraArgs; }
    ] ++ lib.my.mkProfiles profilesDir ++ lib.my.listModulesRecursive modulesDir ++ extraModules;
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
