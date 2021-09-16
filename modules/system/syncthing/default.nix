# modules/system/syncthing/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Syncthing system configuration.

{ config, ... }: {
  services.syncthing = {
    enable = true;
    user = config.user;
    dataDir = "/home/${config.user}";
    overrideFolders = false;
    overrideDevices = false;
    openDefaultPorts = true;
  };
}
