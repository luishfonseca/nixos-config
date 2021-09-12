# modules/system/steam/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Steam system configuration.

{ ... }:
{
  programs.steam.enable = true;
  programs.steam.remotePlay.openFirewall = true;
}
