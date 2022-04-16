{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.shell.dash; in
{
  options.lhf.shell.dash = with types; {
    enable = mkEnableOption "Dash Shell";
    isSystemDefault = mkOption { type = bool; default = true; };
  };

  config.environment.binsh = 
    mkIf (cfg.enable && cfg.isSystemDefault) "${pkgs.dash}/bin/dash";
}
