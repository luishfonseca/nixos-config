{
  config,
  pkgs,
  ...
}: let
  port = 36677;
  url = "https://picgo.lhf.pt";
in {
  systemd.services.picgo = {
    wantedBy = ["multi-user.target"];
    after = ["network.target" "garage.service"];
    requires = ["garage.service"];
    serviceConfig = {
      ExecStart = "${pkgs.lhf.picgo-shim}/bin/picgo-server";
      EnvironmentFile = config.sops.secrets.picgo-env.path;
      DynamicUser = true;
      RuntimeDirectory = "picgo";
      Restart = "on-failure";
    };
    environment = rec {
      HOME = "/run/picgo";
      PICGO_HOST = "127.0.0.1";
      PICGO_PORT = toString port;

      # sudo garage key create picgo
      # sudo garage bucket create img
      # sudo garage bucket allow --read --write --owner img --key picgo
      # sudo garage bucket allow --read --write --owner img --key admin
      # sudo garage bucket website --allow img
      PICGO_S3_ENDPOINT = "https://s3.lhf.pt";
      PICGO_S3_REGION = "garage";
      PICGO_S3_BUCKET = "img";
      PICGO_S3_KEY = "GKa6aed5a23ed1a57b267d864f";
      PICGO_S3_PATH_STYLE_ACCESS = "true";
      PICGO_S3_OUTPUT_URL_PATTERN = "https://img.lhf.pt/{path:/img\//i,''}";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts.${url} = {
      useACMEHost = "lhf.pt";
      extraConfig = ''
        log {
            format filter {
                request>uri query {
                    replace key REDACTED
                }
            }
        }

        @allowed remote_ip 100.64.0.0/10 127.0.0.1
        handle @allowed {
            handle /shim* {
                vars token {query.key}
                rewrite * /shim?
                reverse_proxy :${toString port} {
                    header_up Authorization "Bearer {vars.token}"
                }
            }

            reverse_proxy :${toString port}
        }

        handle {
            respond 403
        }
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [443];
}
