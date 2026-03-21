{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.lhf.tailscale;
in {
  options.lhf.tailscale = with lib; {
    enable = mkEnableOption "Tailscale networking with MagicDNS and auto-operator setup";
    tailnet = mkOption {
      type = types.str;
      description = "Tailnet DNS suffix to add to resolved search domains.";
    };
    autostart = {
      enable = mkOption {
        type = types.bool;
        default = builtins.hasAttr "tailscale-auth-key" config.sops.secrets;
        description = "Automatically authenticate to the tailnet using a sops-managed auth key.";
      };
      extraTags = mkOption {
        type = types.listOf types.str;
        default = ["fleet"];
        description = "Additional ACL tags to advertise (without the `tag:` prefix). The hostname is always included.";
      };
    };
    exitNode = {
      enable = mkEnableOption "NetworkManager-based VPN toggle for a Tailscale exit node";
      node = mkOption {
        type = types.str;
        description = "Tailscale hostname of the exit node to route traffic through.";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services = {
        tailscale = {
          enable = true;
          openFirewall = true;
          extraSetFlags = ["--operator=${config.user.name}"];
        };

        resolved.domains = [cfg.tailnet];
      };

      networking.nameservers = lib.mkBefore ["100.100.100.100"];
    }
    (lib.mkIf cfg.autostart.enable {
      services.tailscale = {
        authKeyFile = config.sops.secrets.tailscale-auth-key.path;
        authKeyParameters = {
          ephemeral = false;
          preauthorized = true;
        };
        extraUpFlags = let
          allTags = cfg.autostart.extraTags ++ [config.networking.hostName];
          tags = lib.concatMapStringsSep "," (t: "tag:${t}") allTags;
        in ["--advertise-tags=${tags}"];
      };
    })
    (lib.mkIf cfg.exitNode.enable {
      services.tailscale.useRoutingFeatures = "client";

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
                  ${pkgs.tailscale}/bin/tailscale set --exit-node=${cfg.exitNode.node}
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
    })
  ]);
}
