{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.services.syncthing; in
{
  options.lhf.services.syncthing.enable = mkEnableOption "Syncthing";

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      systemService = true;
      openDefaultPorts = true;
    };

    user.extraGroups = [ "syncthing" ];

    environment.variables.PASSWORD_STORE_DIR = "/var/lib/syncthing/password-store";
  };
}
