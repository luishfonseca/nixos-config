{
  config,
  options,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  options = with lib; {
    persist = mkOption {type = types.attrs;};
  };

  config.environment.persistence."/nix/pst" = lib.mkAliasDefinitions options.persist;
}
