{
  config,
  lib,
  pkgs,
  ...
}: let
  hosts = {
    opencloud = "cloud.lhf.pt";
    collabora = "office.lhf.pt";
  };

  ports = {
    opencloud = 9200;
    radicale = 5232;
    collabora = 9980;
  };

  csp = (pkgs.formats.yaml {}).generate "csp.yaml" {
    directives = {
      "child-src" = ["'self'"];
      "connect-src" = ["'self'" "blob:" "https://raw.githubusercontent.com/opencloud-eu/awesome-apps/"];
      "default-src" = ["'none'"];
      "font-src" = ["'self'" "https://esm.sh/"];
      "frame-ancestors" = ["'self'"];
      "frame-src" = ["'self'" "blob:" "https://${hosts.collabora}"];
      "img-src" = ["'self'" "data:" "blob:" "https://raw.githubusercontent.com/opencloud-eu/awesome-apps/"];
      "manifest-src" = ["'self'"];
      "media-src" = ["'self'"];
      "object-src" = ["'self'" "blob:"];
      "script-src" = ["'self'" "'unsafe-inline'"];
      "style-src" = ["'self'" "'unsafe-inline'"];
    };
  };

  mkRadicaleRoutes = endpoints:
    lib.mapAttrsToList (endpoint: name: {
      inherit endpoint;
      backend = "http://127.0.0.1:${toString ports.radicale}";
      remote_user_header = "X-Remote-User";
      skip_x_access_token = true;
      additional_headers = [{"X-Script-Name" = name;}];
    })
    endpoints;

  excalidraw = pkgs.fetchzip {
    url = "https://github.com/mschneider82/opencloud-excalidraw/releases/download/v0.0.1/web-app-excalidraw.zip";
    stripRoot = false;
    hash = "sha256-dNvj7TDWurCboqr6VMwlBx6D/LNN8DbeJ0/GPVB4SVY=";
  };

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
    mkdir -p $out/excalidraw
    cp -r ${excalidraw}/* $out/excalidraw

    mkdir -p $out/external-sites
    cp -r ${externalSites}/* $out/external-sites
    cp ${externalSitesConfig} $out/external-sites/config.json
  '';
in {
  systemd.services.opencloud = {
    requires = ["garage.service" "coolwsd.service"];
    after = ["garage.service" "coolwsd.service"];
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
          tcp dport ${toString ports.radicale} meta skuid 990 accept
          tcp dport ${toString ports.radicale} reject
        }
      '';
    };
  };

  services = {
    opencloud = {
      enable = true;
      url = "https://${hosts.opencloud}";
      port = ports.opencloud;
      address = "127.0.0.1";
      environment = {
        OC_LOG_LEVEL = "warn";
        OC_ADD_RUN_SERVICES = "collaboration";
      };
      environmentFile = config.sops.secrets.opencloud-env.path;
      settings = {
        frontend.check_for_updates = false;
        web.asset.apps_path = webApps;
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
          csp_config_file_location = csp;
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
        collaboration = {
          wopi.wopisrc = "https://${hosts.opencloud}";
          app = {
            name = "Office";
            product = "Collabora";
            addr = "http://127.0.0.1:${toString ports.collabora}";
            insecure = true;
            proofkeys.disable = true;
          };
        };
      };
    };

    radicale = {
      enable = true;
      settings = {
        server = {
          hosts = ["127.0.0.1:${toString ports.radicale}"];
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

    collabora-online = {
      enable = true;
      port = ports.collabora;
      settings = {
        ssl = {
          enable = false;
          termination = true;
        };
        net = {
          listen = "127.0.0.1";
          post_allow.host = ["127.0.0.1"];
        };
        storage.wopi = {
          "@allow" = true;
          host = [hosts.opencloud];
        };
        server_name = hosts.collabora;
      };
    };

    caddy = {
      enable = true;
      virtualHosts = {
        ${hosts.opencloud} = {
          useACMEHost = "lhf.pt";
          extraConfig = ''
            @allowed remote_ip 100.64.0.0/10 127.0.0.1
            handle @allowed {
                reverse_proxy :${toString ports.opencloud}
            }

            @public path /s/* /files/upload/* /remote.php/dav/public-files/* /external-office/public/* /app/list /app/open /ocs/v1.php/cloud/capabilities
            handle @public {
                reverse_proxy :${toString ports.opencloud}
            }

            @static path_regexp \.(js|mjs|css|woff2?|ttf|svg|png|jpe?g|ico|json)$
            handle @static {
                reverse_proxy :${toString ports.opencloud}
            }

            handle {
                respond 403
            }
          '';
        };
        ${hosts.collabora} = {
          useACMEHost = "lhf.pt";
          extraConfig = ''
            reverse_proxy :${toString ports.collabora}
          '';
        };
      };
    };
  };

  fileSystems."/usr/share/fonts/collabora" = {
    device = "${pkgs.symlinkJoin {
      name = "collabora-fonts";
      paths = with pkgs; [
        nerd-fonts.departure-mono
        corefonts
      ];
    }}/share/fonts";
    options = ["bind"];
  };

  networking.firewall.allowedTCPPorts = [443];
}
