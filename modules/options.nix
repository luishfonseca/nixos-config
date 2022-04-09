{ config, options, lib, inputs, user, ... }:

with lib;
{
  options = with types; {
    user = mkOption {
      type = attrs;
      default = {};
    };
  };

  config = {
    user = {
      name = user;
      extraGroups = [ "wheel" ];
      isNormalUser = true;
    };

    users.users.${config.user.name} = mkAliasDefinitions options.user;

    nix = let users = [ "root" config.user.name ]; in {
      trustedUsers = users;
      allowedUsers = users;
    };
  };
    
}
