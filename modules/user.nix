{
  config,
  options,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  options = with lib.types; {
    user = lib.mkOption {type = attrs;};
    hm = lib.mkOption {type = attrs;};
  };

  config = {
    users.users.${config.user.name} = lib.mkAliasDefinitions options.user;

    user = {
      extraGroups = ["wheel"];
      isNormalUser = true;
    };

    nix.settings.allowed-users = ["root" config.user.name];

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      users.${config.user.name} = lib.mkAliasDefinitions options.hm;
    };

    hm.home.stateVersion = config.system.stateVersion;
  };
}
