# modules/system/autologin/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Auto login system configuration.

{ config, ... }: {
  services.xserver.displayManager = {
    autoLogin = {
      enable = true;
      inherit (config) user;
    };
    lightdm = {
      enable = true;
      greeter.enable = false;
    };
  };
}
