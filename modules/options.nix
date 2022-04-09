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
      binDir = mkOption { type = path; default = "${config.dotfiles.dir}/bin"; };
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

    # Makes sure these are set before environment.variables
    environment.sessionVariables = {
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_CACHE_HOME  = "$HOME/.cache";
      XDG_DATA_HOME   = "$HOME/.local/share";
      XDG_STATE_HOME  = "$HOME/.local/state";
    };

    environment.variables = {
      DOTFILES = "${config.dotfiles.dir}";
      DOTFILES_BIN = "${config.dotfiles.binDir}";
      PATH = "$DOTFILES_BIN:$HOME/.local/bin:$PATH";
    };
  };
}
