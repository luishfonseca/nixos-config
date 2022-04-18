{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.programs.rofi; in
{
  options.lhf.programs.rofi.enable = mkEnableOption "rofi";

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rofi ];

    home.configFile.rofi.source = "${config.dotfiles.configDir}/rofi";
  };
}
