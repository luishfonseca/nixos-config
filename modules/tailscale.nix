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
    splitDns = {
      enable = mkEnableOption "split DNS via Unbound, resolving a custom domain to this host's Tailscale address";
      domain = mkOption {
        type = types.str;
        description = "Domain to resolve to this host within the tailnet (e.g., lhf.pt)";
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

        # TODO: does it make sense to set ~. on common/networking.nix?
        resolved.domains = lib.mkForce []; # global ~. breaks dns
      };

      networking.firewall.trustedInterfaces = [config.services.tailscale.interfaceName];
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
    # Requires adding this host's Tailscale IP as a nameserver restricted
    # to the configured domain in the Tailscale admin console:
    # https://login.tailscale.com/admin/dns
    (lib.mkIf cfg.splitDns.enable {
      services.unbound = {
        enable = true;
        resolveLocalQueries = false;
        settings = {
          server = {
            interface = [config.services.tailscale.interfaceName];
            access-control = ["100.64.0.0/10 allow"];
            local-zone = [''"${cfg.splitDns.domain}." redirect''];
            local-data = [''"${cfg.splitDns.domain}. IN CNAME ${config.networking.hostName}.${cfg.tailnet}."''];
          };
          forward-zone = [{
            name = "${cfg.tailnet}.";
            forward-addr = ["100.100.100.100"];
          }];
        };
      };

      networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
        allowedTCPPorts = [53];
        allowedUDPPorts = [53];
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
