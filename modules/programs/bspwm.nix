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
      "sxhkd/sxhkdrc".source = "${config.dotfiles.configDir}/sxhkd/sxhkdrc";
      "polybar/config.ini".source = "${config.dotfiles.configDir}/polybar/config.ini";
    };

    environment.systemPackages = [ pkgs.polybar ];
  };
}
