{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.services.picom; in
{
  options.lhf.services.picom.enable = mkEnableOption "Picom";

  config.services.picom = mkIf cfg.enable {
    enable = true;
    backend = "glx";
    vSync = true;
    fade = true;
    fadeDelta = 5;
  };
}
