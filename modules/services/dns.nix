{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.services.dns; in
{
  options.lhf.services.dns = {
    enable = mkEnableOption "DNS server";
    forward = mkOption {
      type = types.listOf types.str;
      description = "List of upstream DNS servers";
    };
    cache = mkOption {
      type = types.int;
      default = 0;
      description = "Cache TTL in seconds";
    };
    magicDNS = {
      enable = mkEnableOption "Magic DNS";
      domain = mkOption {
        type = types.str;
        example = "in.example.com";
        description = "Domain name to use for Magic DNS";
      };
      tailnet = mkOption {
        type = types.str;
        example = "tail9db2a.ts.net";
        description = "Tailscale's tailnet";
      };
    };
  };

  config =
    let
      escape = replaceStrings [ "." ] [ "\." ];
      corednsConfig = optionalString cfg.magicDNS.enable ''
        ${cfg.magicDNS.domain} {
          rewrite name suffix ${cfg.magicDNS.domain} ${cfg.magicDNS.tailnet} answer auto
          forward . 100.100.100.100
        }
        100.in-addr.arpa {
          rewrite stop {
            name suffix arpa arpa
            answer name auto
            answer value (.*)\.${escape cfg.magicDNS.tailnet} {1}.${escape cfg.magicDNS.domain}
          }
          forward . 100.100.100.100
        }
      '' + ''
        . {
          forward . ${concatStringsSep " " cfg.forward}
          ${optionalString (cfg.cache != 0) "cache ${toString cfg.cache}"}
        }
      '';
    in
    mkIf cfg.enable (mkMerge [
      {
        services.coredns = {
          enable = true;
          config = corednsConfig;
        };
        networking.firewall.allowedTCPPorts = [ 53 ];
        networking.firewall.allowedUDPPorts = [ 53 ];
      }
    ]);
}

