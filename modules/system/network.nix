# modules/system/network.nix
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
}
