{ config, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.obsidian ];

  services.syncthing = {
    enable = true;
    user = config.user.name;

    openDefaultPorts = true;
    overrideDevices = false;
    overrideFolders = false;

    dataDir = "/home/${config.user.name}/.local/share/syncthing";

    folders."Obsidian Vault".path = "/home/${config.user.name}/vault";
  };
}
