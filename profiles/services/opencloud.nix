{
  config,
  lib,
  ...
}: let
  port = 9200;
  radicalePort = 5232;
  name = "opencloud";
  url = "https://${name}.${config.lhf.tailscale.tailnet}";

  mkRadicaleRoutes = endpoints:
    lib.mapAttrsToList (endpoint: name: {
      inherit endpoint;
      backend = "http://127.0.0.1:${toString radicalePort}";
      remote_user_header = "X-Remote-User";
      skip_x_access_token = true;
      additional_headers = [{"X-Script-Name" = name;}];
    })
    endpoints;
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
      environmentFile = config.sops.secrets.opencloud-env.path;
      settings = {
        storage-users = {
          # sudo garage key create opencloud
          # sudo garage bucket create opencloud
          # sudo garage bucket allow --read --write --owner opencloud --key opencloud
          # sudo garage bucket allow --read opencloud --key admin
          driver = "decomposeds3";
          drivers.decomposeds3 = {
            endpoint = "https://s3.${config.lhf.tailscale.tailnet}";
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

    caddy.virtualHosts = {
      "${name}:80".extraConfig = ''
        bind tailscale/${name}
        redir ${url} permanent
      '';
      ${url}.extraConfig = ''
        bind tailscale/${name}
        reverse_proxy :${toString port}
      '';
    };
  };
}
