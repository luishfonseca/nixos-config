{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.services.reverseProxy; in
{
  options.lhf.services.reverseProxy = {
    enable = mkEnableOption "Reverse Proxy";
    sites = mkOption {
      type = types.attrsOf (types.attrsOf types.str);
      default = { };
      example = {
        "example.com"."/" = "http://localhost:8000";
      };
      description = "Sites to proxy";
    };
  };

  config.services.nginx = mkIf cfg.enable {
    enable = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    virtualHosts = mapAttrs
      (_: locations: {
        forceSSL = true;
        enableACME = true;
        locations = mapAttrs
          (_: backend: { proxyPass = backend; })
          locations;
      })
      cfg.sites;
  };
}
