{ config, options, lib, inputs, cfg, ... }:

with lib;
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  options = with types; {
    user = mkOption {
      type = attrs;
      default = {
        name = cfg.user;
        extraGroups = [ "wheel" ];
        isNormalUser = true;
      };
    };

    dotfiles = {
      dir = mkOption { type = path; default = cfg.root; };
      configDir = mkOption { type = path; default = "${config.dotfiles.dir}/config"; };
    };

    home = {
      file = mkOption { type = attrs; default = {}; }; # Place in $HOME
      configFile = mkOption { type = attrs; default = {}; }; # Place in $XDG_CONFIG_HOME
      dataFile = mkOption { type = attrs; default = {}; }; # Place in $XDG_DATA_HOME
    };
  };

  config = {
    users.users.${config.user.name} = mkAliasDefinitions options.user;

    nix = let users = [ "root" config.user.name ]; in {
      trustedUsers = users;
      allowedUsers = users;
    };

    home-manager = {
      useUserPackages = true;
      users.${config.user.name} = {
        home = {
          file = mkAliasDefinitions options.home.file;
          stateVersion = config.system.stateVersion;
        };
        xdg = {
          enable = true;
          configFile = mkAliasDefinitions options.home.configFile;
          dataFile = mkAliasDefinitions options.home.dataFile;
        };
      };
    };
  };
    
}
