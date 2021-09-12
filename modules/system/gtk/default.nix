# modules/system/gtk/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# System configuration gtk requires.

{ pkgs, ... }: 
{
  services.dbus.packages = [ pkgs.gnome3.dconf ];
}
