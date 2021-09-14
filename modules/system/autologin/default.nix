# modules/system/autologin/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Auto login system configuration.

{ ... }: {
  services.xserver.displayManager.autoLogin = {
    enable = true;
    user = "luis"; # TODO: make this a variable
  };
}
