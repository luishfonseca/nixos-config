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

  options = with lib; {
    user = mkOption {type = types.attrs;};
    hm = mkOption {type = types.attrs;};
  };

  config = {
    users = {
      mutableUsers = false;
      users.${config.user.name} = lib.mkAliasDefinitions options.user;
    };

    user = {
      isNormalUser = true;
      hashedPasswordFile = lib.mkDefault "/etc/hashedPassword";
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      users.${config.user.name} = lib.mkAliasDefinitions options.hm;
    };

    hm.home.stateVersion = config.system.stateVersion;
  };
}
