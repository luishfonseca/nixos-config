{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.programs.bspwm; in
{
  options.lhf.programs.bspwm.enable = mkEnableOption "BSPWM";

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      windowManager.bspwm.enable = true;
    };

    home.configFile = {
      polybar = {
        source = "${config.dotfiles.configDir}/polybar/";
        onChange = ''
          $XDG_CONFIG_HOME/polybar/launch.sh
        '';
      };
      "sxhkd/sxhkdrc" = {
        source = "${config.dotfiles.configDir}/sxhkd/sxhkdrc";
        onChange = ''
          pkill -USR1 sxhkd
        '';
      };
      "bspwm/bspwmrc".source = "${config.dotfiles.configDir}/bspwm/bspwmrc";
    };

    environment.systemPackages = [ pkgs.polybar ];
  };
}
