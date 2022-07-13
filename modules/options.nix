{ config, options, lib, inputs, extraArgs, ... }:

with lib;
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  options = with types; {

    user = mkOption { type = attrs; };
    hm = mkOption { type = attrs; };

    dotfiles = {
      dir = mkOption { type = path; default = extraArgs.root; };
      configDir = mkOption { type = path; default = "${config.dotfiles.dir}/config"; };
      binDir = mkOption { type = path; default = "${config.dotfiles.dir}/bin"; };
    };

  };

  config = {
    users.users.${config.user.name} = mkAliasDefinitions options.user;

    user = {
      extraGroups = [ "wheel" ];
      name = extraArgs.user;
      isNormalUser = true;
    };

    nix = let users = [ "root" config.user.name ]; in
      {
        trustedUsers = users;
        allowedUsers = users;
      };

    home-manager = {
      useUserPackages = true;
      users.${config.user.name} = mkAliasDefinitions options.hm;
    };

    hm.xdg.enable = true;
    hm.home.stateVersion = config.system.stateVersion;

    # Makes sure these are set before environment.variables
    environment.sessionVariables = {
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
    };

    environment.variables = {
      DOTFILES = "${config.dotfiles.dir}";
      DOTFILES_BIN = "${config.dotfiles.binDir}";
      PATH = "$HOME/.local/bin:$DOTFILES_BIN:$PATH";
    };

  };
}
