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
    services.userborn.enable = true;
    systemd.services.userborn = {
      wantedBy = ["dbus-daemon.service"];
      before = ["dbus-daemon.service"];
    };

    users = {
      mutableUsers = false;
      users.${config.user.name} = lib.mkAliasDefinitions options.user;
    };

    user = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.hashedPassword.path;
    };

    sops.secrets.hashedPassword.neededForUsers = true;

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      users.${config.user.name} = lib.mkAliasDefinitions options.hm;
    };

    hm.home.stateVersion = config.system.stateVersion;
  };
}
