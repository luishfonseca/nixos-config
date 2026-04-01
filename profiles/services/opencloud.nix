{config, ...}: let
  port = 9200;
  radicalePort = 5232;
  name = "opencloud";
  url = "https://${name}.${config.lhf.tailscale.tailnet}";
in {
  imports = [
    ./caddy-tailscale.nix
  ];

  systemd.services.opencloud = {
    requires = ["garage.service"];
    after = ["garage.service"];
  };

  persist.system.directories = ["/etc/opencloud"];

  services = {
    opencloud = {
      enable = true;
      inherit url port;
      address = "127.0.0.1";
      environment = {
        PROXY_TLS = "false";

        # sudo garage key create opencloud
        # sudo garage bucket create opencloud
        # sudo garage bucket allow --read --write --owner opencloud --key opencloud
        # sudo garage bucket allow --read opencloud --key admin
        STORAGE_USERS_DRIVER = "decomposeds3";
        STORAGE_USERS_DECOMPOSEDS3_ENDPOINT = "https://s3.${config.lhf.tailscale.tailnet}";
        STORAGE_USERS_DECOMPOSEDS3_REGION = "garage";
        STORAGE_USERS_DECOMPOSEDS3_BUCKET = "opencloud";
        STORAGE_USERS_DECOMPOSEDS3_ACCESS_KEY= "GK460de077d300ba9f0d38c91e";
      };
      environmentFile = config.sops.secrets.opencloud-env.path;
    };

    radicale = {
      enable = true;
      settings = {
        server = {
          hosts = ["127.0.0.1:${toString radicalePort}"];
          ssl = false;
        };
        auth.type = "http_x_remote_user";
      };
    };

    caddy.virtualHosts = {
      "${name}:80".extraConfig = ''
        bind tailscale/${name}
        redir ${url} permanent
      '';
      ${url}.extraConfig = ''
        bind tailscale/${name}

        handle /caldav/* {
          reverse_proxy :${toString radicalePort} {
            header_up X-Script-Name /caldav
          }
        }
        handle /.well-known/caldav {
          reverse_proxy :${toString radicalePort} {
            header_up X-Script-Name /caldav
          }
        }
        handle /carddav/* {
          reverse_proxy :${toString radicalePort} {
            header_up X-Script-Name /carddav
          }
        }
        handle /.well-known/carddav {
          reverse_proxy :${toString radicalePort} {
            header_up X-Script-Name /carddav
          }
        }

        handle {
          reverse_proxy :${toString port}
        }
      '';
    };
  };
}
