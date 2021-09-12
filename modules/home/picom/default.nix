# modules/home/picom.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Picom home configuration.

{ ... }:

{
  services.picom = {
    enable = true;
    blur = true;
    fade = false;
    inactiveDim = "0.2";
    vSync = true;
  };
}
