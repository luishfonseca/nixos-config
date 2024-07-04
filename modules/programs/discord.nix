{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.programs.discord; in
{
  options.lhf.programs.discord.enable = mkEnableOption "Discord";

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.discord ];
  };
}
