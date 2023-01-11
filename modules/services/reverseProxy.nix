{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.services.reverseProxy; in
{
  options.lhf.services.reverseProxy = {
    enable = mkEnableOption "Reverse Proxy";
    sites = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Sites to proxy";
    };
  };

  config.services.nginx = mkIf cfg.enable {
    enable = true;
    virtualHosts = mapAttrs
      (_: backend: {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass = backend;
      })
      cfg.sites;
  };
}
