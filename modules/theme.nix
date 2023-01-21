{ config, options, lib, ... }:

{
  options.lhf.theme.enable = lib.mkEnableOption "theme configuration";
  config = lib.mkIf config.lhf.theme.enable {
    hm.gtk = {
      enable = true;
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    };

    hm.dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };
}
