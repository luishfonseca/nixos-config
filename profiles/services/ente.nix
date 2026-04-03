{
  config,
  pkgs,
  ...
}: let
  port = 8094;
  hosts = {
    api = "ente.lhf.pt";
    accounts = "ente-accounts.lhf.pt";
    photos = "photos.lhf.pt";
    cast = "cast.lhf.pt";
    public-albums = "albums.lhf.pt";
  };
in {
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
          cast = "https://${hosts.cast}";
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
            endpoint = "https://s3.lhf.pt";
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
    caddy = {
      enable = true;
      virtualHosts = let
        webApp = enteApp:
          config.services.ente.web.package.override {
            inherit enteApp;
            enteMainUrl = "https://${hosts.photos}";
            extraBuildEnv = {
              NEXT_PUBLIC_ENTE_ENDPOINT = "https://${hosts.api}";
              NEXT_PUBLIC_ENTE_PHOTOS_ENDPOINT = "https://${hosts.photos}";
              NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT = "https://${hosts.public-albums}";
              NEXT_TELEMETRY_DISABLED = "1";
            };
          };
      in {
        ${hosts.photos} = {
          useACMEHost = "lhf.pt";
          extraConfig = ''
            @allowed remote_ip 100.64.0.0/10 127.0.0.1
            handle @allowed {
                root * ${webApp "photos"}
                try_files {path} {path}.html /index.html
                file_server
                header Access-Control-Allow-Origin "https://${hosts.photos}"
            }

            handle {
                respond 403
            }
          '';
        };
        ${hosts.accounts} = {
          useACMEHost = "lhf.pt";
          extraConfig = ''
            @allowed remote_ip 100.64.0.0/10 127.0.0.1
            handle @allowed {
              root * ${webApp "accounts"}
              try_files {path} {path}.html /index.html
              file_server
              header Access-Control-Allow-Origin "https://${hosts.accounts}"
            }

            handle {
                respond 403
            }
          '';
        };
        ${hosts.api} = {
          useACMEHost = "lhf.pt";
          extraConfig = ''
            @allowed remote_ip 100.64.0.0/10 127.0.0.1
            handle @allowed {
                reverse_proxy :${toString port}
            }

            @public path /public-collection*
            handle  {
                reverse_proxy @public :${toString port}
            }

            handle {
                respond 403
            }
          '';
        };
        ${hosts.cast} = {
          useACMEHost = "lhf.pt";
          extraConfig = ''
            root * ${webApp "cast"}
            try_files {path} {path}.html /index.html
            file_server
            header Access-Control-Allow-Origin "https://${hosts.cast}"
          '';
        };
        ${hosts.public-albums} = {
          useACMEHost = "lhf.pt";
          extraConfig = ''
            root * ${webApp "photos"}
            try_files {path} {path}.html /index.html
            file_server
            header Access-Control-Allow-Origin "https://${hosts.public-albums}"
          '';
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [443];
}
