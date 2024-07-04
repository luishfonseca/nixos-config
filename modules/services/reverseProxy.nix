{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.services.reverseProxy; in
{
  options.lhf.services.reverseProxy = {
    enable = mkEnableOption "Reverse Proxy";
    host = mkOption {
      type = types.str;
      example = "example.com";
      description = "Apex domain";
    };
    acmeHost = mkOption {
      type = types.str;
      example = "acme.example.com";
      description = "Domain name to use for ACME challenge";
    };
    sites = mkOption {
      type = types.attrsOf (types.attrsOf types.str);
      default = { };
      example = {
        "example.com"."/" = "http://localhost:8000";
      };
      description = "Sites to proxy";
    };
  };

  config = mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults.email = "luis@lhf.pt";

      certs.${cfg.acmeHost} = {
        domain = "*.${cfg.host}";
        dnsProvider = "ovh";
        dnsPropagationCheck = true;
        credentialsFile = "/root/ovh.creds";
      };
    };

    users.users.nginx.extraGroups = [ "acme" ];

    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
      virtualHosts = {
        "_" = {
          forceSSL = true;
          useACMEHost = cfg.acmeHost;
          default = true;
          globalRedirect = cfg.host;
        };
      } // mapAttrs
        (_: locations: {
          forceSSL = true;
          useACMEHost = cfg.acmeHost;
          locations = mapAttrs
            (_: backend: { proxyPass = backend; })
            locations;
        })
        cfg.sites;
    };
  };
}
