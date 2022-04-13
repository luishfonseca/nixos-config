{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.programs.kitty; in {
  options.lhf.programs.kitty.enable = mkEnableOption "Alacritty";

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.kitty ];

    home.configFile."kitty/kitty.conf".source = "${config.dotfiles.configDir}/kitty/kitty.conf";
  };
}
