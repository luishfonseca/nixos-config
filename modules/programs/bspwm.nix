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
      "bspwm/bspwmrc".source = "${config.dotfiles.configDir}/bspwm/bspwmrc";
      "polybar/config.ini".source = "${config.dotfiles.configDir}/polybar/config.ini";
      "sxhkd/sxhkdrc" = {
        source = "${config.dotfiles.configDir}/sxhkd/sxhkdrc";
        onChange = ''
          pkill -USR1 sxhkd
        '';
      };
    };

    environment.systemPackages = [ pkgs.polybar ];
  };
}
