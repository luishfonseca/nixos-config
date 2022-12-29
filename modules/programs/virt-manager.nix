{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.programs.virtManager; in
{
  options.lhf.programs.virtManager = with types; {
    enable = mkEnableOption "Virt Manager";
    mutableConnections = mkOption { type = bool; default = false; };
    autoconnectAll = mkOption { type = bool; default = false; };
    connections = mkOption { type = listOf str; default = [ ]; };
  };

  config = mkIf cfg.enable
    (mkMerge [
      {
        environment.systemPackages = [ pkgs.virt-manager ];
      }
      (mkIf (cfg.mutableConnections == false) {
        programs.dconf.enable = true;
        system.userActivationScripts.virtManager.text =
          let
            connections = if cfg.connections != [ ] then cfg.connections else [ "qemu:///system" ];
            formatConnections = conns: "[${strings.concatMapStringsSep ", " (s: "'${s}'") conns}]";
          in
          ''
            ${pkgs.dconf}/bin/dconf load / << EOF
            [org/virt-manager/virt-manager/connections]
            uris=${formatConnections connections}
            ${if cfg.autoconnectAll then "autoconnect=${formatConnections connections}" else ""}
            EOF
          '';
      })
    ]);
}
