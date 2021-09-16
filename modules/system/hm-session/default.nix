# modules/system/hm-session/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Dummy session that only runs home manager's .xsession.

{ ... }: {
  services.xserver = {
    enable = true;
    displayManager = {
      defaultSession = "none+hm-xsession";
      session = [{
        manage = "window";
        name = "hm-xsession";
        start = "";
      }];
    };
  };
}
