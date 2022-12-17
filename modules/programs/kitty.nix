{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.programs.kitty; in
{
  options.lhf.programs.kitty.enable = mkEnableOption "Kitty";

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.kitty ];

    hm.xdg.configFile."kitty/kitty.conf".source = "${config.dotfiles.configDir}/kitty/kitty.conf";
  };
}
