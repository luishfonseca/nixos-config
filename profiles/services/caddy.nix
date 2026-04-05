{
  config,
  pkgs,
  ...
}: let 
  nameserver = "100.123.137.111"; # pollux
in {
  security.acme = {
    acceptTerms = true;
    defaults.email = "luis@lhf.pt";
    certs."lhf.pt" = {
      extraDomainNames = ["*.lhf.pt"];
      group = "caddy";
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets.cf-dns-api-token.path;
    };
  };

  users.users.caddy.extraGroups = ["keys"];
  sops.secrets.caddy-ddns-env.owner = "caddy";

  systemd.services.caddy.after = ["bind.service"];

  services.caddy = {
    enable = true;
    environmentFile = config.sops.secrets.caddy-ddns-env.path;
    logFormat = "level INFO";
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/luishfonseca/caddy-cname-sync@v0.1.0"
        "github.com/caddy-dns/rfc2136@v1.0.0"
      ];
      hash = "sha256-rLzHmyF3q/woBioVD0nRObbNFPy8I4N2hbYuOecRtfU=";
    };
    globalConfig = ''
      cname_sync {
          zone     rpz
          target   ${config.networking.hostName}.${config.lhf.tailscale.tailnet}
          ttl      5m
          strict   false
          provider rfc2136 {
              key_name "ddns"
              key_alg "hmac-sha256"
              key "{$DDNS_SECRET}"
              server "${nameserver}:53"
          }
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
