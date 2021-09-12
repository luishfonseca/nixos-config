# modules/system/network/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Network system configuration.

{ ... }:
{
  networking.networkmanager = {
    enable = true;
    insertNameservers = [ "1.1.1.1" "1.0.0.1" ];
  };
  users.users.luis.extraGroups = [ "networkmanager" ];

  systemd.services.NetworkManager-wait-online.enable = false;

  environment.persistence."/nix/persist".directories = [
    "/etc/NetworkManager/system-connections"
  ];
}
