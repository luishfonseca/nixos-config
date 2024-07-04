{
  config,
  options,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.lhf.programs.rofi;
in {
  options.lhf.programs.rofi.enable = mkEnableOption "rofi";

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.rofi];

    hm.xdg.configFile."rofi/config.rasi".source = "${config.dotfiles.configDir}/rofi/config.rasi";
  };
}
