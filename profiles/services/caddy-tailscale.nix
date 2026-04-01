{
  pkgs,
  config,
  ...
}: {
  systemd.services.caddy = {
    after = ["network-online.target"];
    wants = ["network-online.target"];
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/tailscale/caddy-tailscale@v0.0.0-20260106222316-bb080c4414ac"];
      hash = "sha256-9CYQSdGAQwd1cmFuKT2RNzeiJ4DZoyrxvsLS4JDCFCY=";
    };
    environmentFile = config.sops.secrets.caddy-ts-authkey.path;
    globalConfig = ''
      tailscale {
        tags tag:caddy
      }
    '';
  };
}
