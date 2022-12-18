self: super: {
  my = (super.lib.mapAttrs'
    (name: value: super.lib.nameValuePair
      (super.lib.removeSuffix ".nix" name)
      (super.callPackage ../packages/${name} { }))
    (builtins.readDir ../packages));
}
