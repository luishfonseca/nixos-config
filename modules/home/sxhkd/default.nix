# modules/home/sxhkd.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# SXHKD home configuration.

{ ... }:

{
  services.sxhkd = {
    enable = true;
    keybindings = {
      "super + Escape" = "pkill -USR1 -x sxhkd"; # reload sxhkd
    };
  };
}
