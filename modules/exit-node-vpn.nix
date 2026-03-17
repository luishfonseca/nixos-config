{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.lhf.exitNodeVpn;
in {
  options.lhf.exitNodeVpn = with lib; {
    enable = mkEnableOption "VPN toggle for Tailscale exit node";
    node = lib.mkOption {
      type = types.str;
      description = "The hostname of the exit node";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."NetworkManager/system-connections/tailscale-exit.nmconnection" = {
      mode = "0600";
      text = lib.generators.toINI {} {
        connection = {
          id = "Tailscale Exit Node";
          type = "wireguard";
          interface-name = "ts-exit-dummy";
          autoconnect = "false";
        };
        ipv4.method = "disabled";
        ipv6.method = "disabled";

        # dummy key, this isn't an actual secret
        wireguard.private-key = "6EygDEHeSbcSqPPr0XgOnLre9xbYitHld3t7KPNqq20=";
      };
    };

    networking.networkmanager.dispatcherScripts = [
      {
        source = pkgs.writeScript "tailscale-exit-toggle" ''
          #!/bin/sh
          if [ "$CONNECTION_ID" = "Tailscale Exit Node" ]; then
            case "$2" in
              up)
                ${pkgs.tailscale}/bin/tailscale set --exit-node=${cfg.node}
                ;;
              down)
                ${pkgs.tailscale}/bin/tailscale set --exit-node=
                ;;
            esac
          fi
        '';
        type = "basic";
      }
    ];

    services.tailscale.useRoutingFeatures = "client";
  };
}
