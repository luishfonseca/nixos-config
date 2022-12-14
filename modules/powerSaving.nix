{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.powerSaving; in
{
  options.lhf.powerSaving.enable = mkEnableOption "Power Saving";

  config = mkIf cfg.enable {
    powerManagement.powertop.enable = true;
    networking.networkmanager.wifi.powersave = true;
    services.thermald.enable = true;
    services.auto-cpufreq.enable = true;
  };
}
