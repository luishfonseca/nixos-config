{
  config,
  pkgs,
  lib,
  ...
}: let
  port = 8094;
  hosts = {
    photos = "photos.${config.lhf.tailscale.tailnet}";
    accounts = "ente-accounts.${config.lhf.tailscale.tailnet}";
    api = "ente-api.${config.lhf.tailscale.tailnet}";
    public-albums = "albums.lhf.pt";
    public-api = "ente-api.lhf.pt";
    public-s3 = "s3.lhf.pt";
  };
in {
  imports = [
    ./caddy-tailscale.nix
  ];

  systemd.services.ente = {
    requires = ["garage.service"];
    after = ["garage.service"];
  };

  sops.secrets = {
    ente-s3-secret.owner = "ente";
    ente-key-encryption.owner = "ente";
    ente-key-hash.owner = "ente";
    ente-jwt-secret.owner = "ente";
  };

  environment.variables.ENTE_CLI_SECRETS_PATH = "$HOME/.ente/secrets.txt";
  environment.systemPackages = [pkgs.ente-cli];
  persist.home.directories = [".ente"];

  services = {
    ente.api = {
      enable = true;
      enableLocalDB = true;
      domain = hosts.api;
      settings = {
        http = {
          port = builtins.toString port;
          use-tls = false;
        };
        apps = {
          accounts = "https://${hosts.accounts}";
          public-albums = "https://${hosts.public-albums}";
        };
        webauthn = {
          rpid = hosts.accounts;
          rporigins = ["https://${hosts.accounts}"];
        };
        s3 = {
          use_path_style_urls = true;
          b2-eu-cen = {
            # sudo garage key create ente
            # sudo garage bucket create ente
            # sudo garage bucket allow --read --write --owner ente --key ente
            # sudo garage bucket allow --read --write --owner ente --key admin
            endpoint = "https://${hosts.public-s3}";
            region = "garage";
            bucket = "ente";
            key = "GK130a7d96cba2f421dd6c03f0";
            secret._secret = config.sops.secrets.ente-s3-secret.path;
          };
        };
        key = {
          encryption._secret = config.sops.secrets.ente-key-encryption.path;
          hash._secret = config.sops.secrets.ente-key-hash.path;
        };
        jwt.secret._secret = config.sops.secrets.ente-jwt-secret.path;
        internal.admin = "1580559962386438";
      };
    };
    caddy.virtualHosts = let
      webApp = enteApp: api:
        config.services.ente.web.package.override {
          inherit enteApp;
          enteMainUrl = "https://${hosts.photos}";
          extraBuildEnv = {
            NEXT_PUBLIC_ENTE_ENDPOINT = "https://${api}";
            NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT = "https://${hosts.public-albums}";
            NEXT_TELEMETRY_DISABLED = "1";
          };
        };
    in {
      "photos:80".extraConfig = ''
        bind tailscale/photos
        redir https://${hosts.photos} permanent
      '';
      ${hosts.photos}.extraConfig = ''
        bind tailscale/photos
        root * ${webApp "photos" hosts.api}
        try_files {path} {path}.html /index.html
        file_server
        header Access-Control-Allow-Origin "https://${hosts.photos}"
      '';
      ${hosts.accounts}.extraConfig = ''
        bind tailscale/ente-accounts
        root * ${webApp "accounts" hosts.api}
        try_files {path} {path}.html /index.html
        file_server
        header Access-Control-Allow-Origin "https://${hosts.accounts}"
      '';
      ${hosts.api}.extraConfig = ''
        bind tailscale/ente-api
        reverse_proxy :${toString port}
      '';
      ${hosts.public-albums} = {
        useACMEHost = "lhf.pt";
        extraConfig = ''
          root * ${webApp "photos" hosts.public-api}
          try_files {path} {path}.html /index.html
          file_server
          header Access-Control-Allow-Origin "https://${hosts.public-albums}"
        '';
      };
      ${hosts.public-api} = {
        useACMEHost = "lhf.pt";
        # Filter public api to minimum required to share albums
        extraConfig = ''
          handle /public-collection* {
              reverse_proxy :${toString port}
          }
          handle {
              respond 403
          }
        '';
      };
    };
  };

  networking.firewall.allowedTCPPorts = [443];
}
