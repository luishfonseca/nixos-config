{
  config,
  pkgs,
  lib,
  ...
}: let
  port = 3900;
  rpcPort = 3901;
  adminPort = 3903;
  url = "s3.lhf.pt";
in {
  systemd.services.garage = {
    requires = ["vault.service"];
    after = ["vault.service"];
    serviceConfig.SupplementaryGroups = ["box"];
  };

  environment.systemPackages = [pkgs.minio-client];
  persist.home.directories = [".mc"];

  services = {
    garage = {
      enable = true;
      package = pkgs.garage_2;
      environmentFile = config.sops.secrets.garage-env.path;

      settings = {
        data_dir = "/mnt/vault/garage";
        db_engine = "sqlite";
        replication_factor = 1;
        compression_level = 19;

        rpc_bind_addr = "127.0.0.1:${toString rpcPort}";
        rpc_public_addr = "127.0.0.1:${toString rpcPort}";
        rpc_secret = "@env:GARAGE_RPC_SECRET";

        s3_api = {
          api_bind_addr = "127.0.0.1:${toString port}";
          s3_region = "garage";
        };

        admin = {
          api_bind_addr = "127.0.0.1:${toString adminPort}";
          admin_token = "@env:GARAGE_ADMIN_TOKEN";
        };
      };
    };

    caddy = {
      enable = true;
      virtualHosts.${url} = let
        public = {
          ente = "GET HEAD PUT OPTIONS";
        };
      in {
        useACMEHost = "lhf.pt";
        extraConfig = ''
          @tailscale remote_ip 100.64.0.0/10
          handle @tailscale {
              reverse_proxy :${toString port}
          }

          ${lib.concatStringsSep "\n\n" (lib.mapAttrsToList (bucket: methods: ''
              @${bucket} {
                  path /${bucket}/*
                  method ${methods}
              }
              handle  {
                  reverse_proxy @${bucket} :${toString port}
              }
            '')
            public)}

          handle {
              respond 403
          }
        '';
      };
    };
  };

  networking.firewall.allowedTCPPorts = [443];
}
