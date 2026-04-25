{
  config,
  lib,
  ...
}: let
  ifthen = field: data: {
    "if" = field;
    "then" = data;
  };
  otherwise = value: {"else" = value;};
in {
  services.stalwart-mail = {
    enable = true;
    openFirewall = true;

    credentials = {
      admin_password = config.sops.secrets.stalwart-admin-password.path;
      smtp2go_password = config.sops.secrets.smtp2go-password.path;
    };

    settings = {
      server = {
        hostname = "mail.lhf.pt";
        tls = {
          enable = true;
          implicit = true;
        };

        listener = {
          smtp = {
            bind = ["[::]:25"];
            protocol = "smtp";
          };

          submissions = {
            bind = ["[::]:465"];
            protocol = "smtp";
            tls.implicit = true;
          };

          imaps = {
            bind = ["[::]:993"];
            protocol = "imap";
            tls.implicit = true;
          };

          management = {
            bind = ["127.0.0.1:8081"];
            protocol = "http";
          };
        };
      };

      lookup = {
        default = {
          hostname = "mail.lhf.pt";
          domain = "lhf.pt";
        };
        spam-traps = {
          "admin@*" = "";
          "administrator@*" = "";
          "info@*" = "";
          "contact@*" = "";
          "sales@*" = "";
          "marketing@*" = "";
          "support@*" = "";
          "help@*" = "";
          "office@*" = "";
          "billing@*" = "";
          "payments@*" = "";
          "team@*" = "";
          "staff@*" = "";
          "all@*" = "";
          "security@*" = "";
          "test@*" = "";
          "testing@*" = "";
          "root@*" = "";
          "user@*" = "";
          "guest@*" = "";
        };
      };

      spam-filter.list.scores.SPAM_TRAP = "discard";

      authentication.fallback-admin = {
        user = "admin";
        secret = "%{file:/run/credentials/stalwart-mail.service/admin_password}%";
      };

      session = {
        auth.must-match-sender = false; # allow to send from any username

        rcpt = {
          rewrite = [
            # rewrite first.last@example.org to first+last@example.org
            (ifthen "is_local_domain('', rcpt_domain) & matches('^([^.]+)\\.([^.]+)@(.+)$', rcpt)" "$1 + '+' + $2 + '@' + $3")
            (otherwise false)

            # TODO: add a robots rewrite
          ];
          directory = [
            (ifthen "key_exists('spam-traps', rcpt)" false)
            (otherwise "'*'")
          ];
          relay = [
            (ifthen "key_exists('spam-traps', rcpt)" true)
            (ifthen "!is_empty(authenticated_as)" true)
            (otherwise false)
          ];
          catch-all = true;
        };
      };

      # Disable DKIM signing. SMTP2GO handles this
      auth.dkim.sign = false;
      report = {
        dkim.sign = false;
        dsn.sign = false;
        dmarc.sign = false;
        dmarc.aggregate.sign = false;
        spf.sign = false;
        tls.aggregate.sign = false;
      };
      sieve.trusted.sign = false;

      queue = {
        route = {
          smtp2go = {
            type = "relay";
            address = "mail.smtp2go.com";
            protocol = "smtp";
            port = 8465;
            tls.implicit = true;
            auth = {
              username = "luis@lhf.pt";
              secret = "%{file:/run/credentials/stalwart-mail.service/smtp2go_password}%";
            };
          };

          local.type = "local";
        };

        strategy.route = [
          (ifthen "is_local_domain('', rcpt_domain)" "'local'")
          (otherwise "'smtp2go'")
        ];
      };

      store.db = lib.mkForce {
        type = "postgresql";
        host = "/run/postgresql";
        database = "stalwart-mail";
        user = "stalwart-mail";
      };

      certificate.main = {
        cert = "%{file:/var/lib/acme/lhf.pt/cert.pem}%";
        private-key = "%{file:/var/lib/acme/lhf.pt/key.pem}%";
      };
    };
  };

  users.users.stalwart-mail.extraGroups = ["caddy"];

  systemd.services.stalwart-mail = {
    requires = ["postgresql.service"];
    after = ["postgresql.service"];
    serviceConfig.RestrictAddressFamilies = ["AF_UNIX"];
  };

  lhf.localDB = {
    enable = true;
    dbs = ["stalwart-mail"];
  };

  services.caddy.virtualHosts = {
    "autoconfig.lhf.pt" = {
      useACMEHost = "lhf.pt";
      extraConfig = ''
        handle /mail/config-v1.1.xml {
          reverse_proxy 127.0.0.1:8081
        }
        handle {
          respond 404
        }
      '';
    };

    "autodiscover.lhf.pt" = {
      useACMEHost = "lhf.pt";
      extraConfig = ''
        handle /autodiscover/autodiscover.xml {
          reverse_proxy 127.0.0.1:8081
        }
        handle {
          respond 404
        }
      '';
    };

    "mailadmin.lhf.pt" = {
      useACMEHost = "lhf.pt";
      extraConfig = ''
        @allowed remote_ip 100.64.0.0/10 127.0.0.1
        handle @allowed {
          reverse_proxy 127.0.0.1:8081
        }
        handle {
          respond 403
        }
      '';
    };
  };
}
