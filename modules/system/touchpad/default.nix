# modules/system/touchpad/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Touchpad system configuration.

{ ... }: {
  services.xserver.libinput = {
    enable = true;
    touchpad = {
      scrollButton = 2;
      naturalScrolling = true;
    };
  };
}
