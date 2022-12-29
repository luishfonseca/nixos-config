final: prev: {
  my = (prev.lib.mapAttrs'
    (name: value: prev.lib.nameValuePair
      (prev.lib.removeSuffix ".nix" name)
      (prev.callPackage ../packages/${name} { }))
    (builtins.readDir ../packages));
}
