{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.services.picom; in
{
  options.lhf.services.picom.enable = mkEnableOption "Picom";

  config.services.picom = mkIf cfg.enable {
    enable = true;
    backend = "glx";
    vSync = true;
    settings = {
      animations = true;
      animation-exclude = [ "class_g = 'Polybar'" ];
      animation-stiffness = 200;
      animation-window-mass = 1.0;
      animation-dampening = 20;
      animation-clamping = true;
      animation-for-open-window = "zoom";
      animation-for-unmap-window = "squeeze";
      animation-for-transient-window = "slide-down";

      detect-rounded-corners = false;
      detect-client-opacity = false;
      detect-transient = true;
      detect-client-leader = true;
      use-ewmh-active-win = true;
      unredir-if-possible = false;
      glx-no-stencil = true;
      xrender-sync-fence = true;
      use-damage = true;
    };
  };
}
