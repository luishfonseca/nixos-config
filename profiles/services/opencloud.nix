{
  config,
  lib,
  pkgs,
  ...
}: let
  port = 9200;
  radicalePort = 5232;
  url = "https://opencloud.lhf.pt";

  mkRadicaleRoutes = endpoints:
    lib.mapAttrsToList (endpoint: name: {
      inherit endpoint;
      backend = "http://127.0.0.1:${toString radicalePort}";
      remote_user_header = "X-Remote-User";
      skip_x_access_token = true;
      additional_headers = [{"X-Script-Name" = name;}];
    })
    endpoints;

  externalSites = pkgs.fetchzip {
    url = "https://github.com/opencloud-eu/web-extensions/releases/download/external-sites-v1.3.0/external-sites-1.3.0.zip";
    hash = "sha256-++ZuTpLkTiAYSbIRzajmzSopfmBqpzY1iG1yCJmxhXA=";
  };

  externalSitesConfig = pkgs.writeText "external-sites-config.json" (builtins.toJSON {
    config.sites = [
      {
        name = "Photos";
        url = "https://photos.lhf.pt";
        target = "external";
        color = "#00B33C";
        icon = "image";
        priority = 50;
      }
    ];
  });

  webApps = pkgs.runCommand "opencloud-web-apps" {} ''
    mkdir -p $out/external-sites
    cp -r ${externalSites}/* $out/external-sites
    cp ${externalSitesConfig} $out/external-sites/config.json
  '';
in {
  systemd.services.opencloud = {
    requires = ["garage.service"];
    after = ["garage.service"];
  };

  persist.system.directories = ["/etc/opencloud"];

  users.users.${config.services.opencloud.user}.uid = 990;
  networking.nftables = {
    enable = true;
    tables.radicale-guard = {
      family = "inet";
      content = ''
        chain output {
          type filter hook output priority 0; policy accept;
          tcp dport ${toString radicalePort} meta skuid 990 accept
          tcp dport ${toString radicalePort} reject
        }
      '';
    };
  };

  services = {
    opencloud = {
      enable = true;
      inherit url port;
      address = "127.0.0.1";
      environment.WEB_ASSET_APPS_PATH = "${webApps}";
      environmentFile = config.sops.secrets.opencloud-env.path;
      settings = {
        storage-users = {
          # sudo garage key create opencloud
          # sudo garage bucket create opencloud
          # sudo garage bucket allow --read --write --owner opencloud --key opencloud
          # sudo garage bucket allow --read opencloud --key admin
          driver = "decomposeds3";
          drivers.decomposeds3 = {
            endpoint = "https://s3.lhf.pt";
            region = "garage";
            bucket = "opencloud";
            access_key = "GK460de077d300ba9f0d38c91e";
          };
        };
        proxy = {
          http.tls = false;
          additional_policies = [
            {
              name = "default";
              routes = mkRadicaleRoutes {
                "/caldav/" = "/caldav";
                "/.well-known/caldav" = "/caldav";
                "/carddav/" = "/carddav";
                "/.well-known/carddav" = "/carddav";
              };
            }
          ];
        };
      };
    };

    radicale = {
      enable = true;
      settings = {
        server = {
          hosts = ["127.0.0.1:${toString radicalePort}"];
          ssl = false;
        };
        auth.type = "http_x_remote_user";
        web.type = "none";
        storage.predefined_collections = builtins.toJSON {
          def-addressbook = {
            "D:displayname" = "OpenCloud Address Book";
            tag = "VADDRESSBOOK";
          };
          def-calendar = {
            "C:supported-calendar-component-set" = "VEVENT,VJOURNAL,VTODO";
            "D:displayname" = "OpenCloud Calendar";
            tag = "VCALENDAR";
          };
        };
      };
    };

    caddy = {
      enable = true;
      virtualHosts.${url} = {
        useACMEHost = "lhf.pt";
        extraConfig = ''
          @tailscale remote_ip 100.64.0.0/10
          handle @tailscale {
              reverse_proxy :${toString port}
          }

          @public path /s/* /files/upload/* /remote.php/dav/public-files/* /app/list
          handle @public {
              reverse_proxy :${toString port}
          }

          @static path_regexp \.(js|mjs|css|woff2?|ttf|svg|png|jpe?g|ico|json)$
          handle @static {
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
