# modules/system/lighdm.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# LightDM system configuration.

{ ... }:
{
  services.xserver = {
    displayManager = {
      lightdm = {
        enable = true;
        greeter.enable = false;
      };

      autoLogin = {
        enable = true;
        user = "luis"; #TODO: make this a variable
      };

      # Dummy session that only runs home manager's .xsession.
      defaultSession = "none+hm-xsession";
      session = [{
        manage = "window";
	name = "hm-xsession";
	start = "";
      }];
    };
  };
}
