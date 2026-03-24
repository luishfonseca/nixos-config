{
  inputs,
  lib,
  ...
}: {
  options.pasta = lib.mkOption {
    type = lib.types.attrs;
    default = {};
    description = "Arbitrary shared values across hosts";
  };

  config.pasta =
    lib.mapAttrs
    (_: cfg: cfg.config.pasta)
    inputs.self.nixosConfigurations;
}
