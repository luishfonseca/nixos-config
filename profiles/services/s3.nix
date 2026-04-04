{
  config,
  pkgs,
  lib,
  ...
}: let
  port = 3900;
  rpcPort = 3901;
  webPort = 3902;
  adminPort = 3903;
  url = "s3.lhf.pt";
  web = ["img.lhf.pt"];
in {
  systemd.services.garage = {
    requires = ["vault.service"];
    after = ["vault.service"];
    serviceConfig.SupplementaryGroups = ["box"];
  };

  environment.systemPackages = [pkgs.minio-client];
  persist.home.directories = [".mc"];

  lhf.backup = {
    exclude = [
      "/nix/pst${config.services.garage.settings.metadata_dir}/db.sqlite"
      "/nix/pst${config.services.garage.settings.metadata_dir}/db.sqlite-shm"
      "/nix/pst${config.services.garage.settings.metadata_dir}/db.sqlite-wal"
    ];
    hooks.garage = {
      user = "root"; # todo change once garage isn't nobody
      depends = ["garage.service"];
      script = pkgs.writeShellScript "pre-backup" ''
        set -a
        . ${config.services.garage.environmentFile}

        rm -rf ${config.services.garage.settings.metadata_dir}/snapshots/*
        exec ${config.services.garage.package}/bin/garage meta snapshot
      '';
    };
  };

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

        s3_web = {
          bind_addr = "127.0.0.1:${toString webPort}";
          root_domain = "lhf.pt";
        };

        admin = {
          api_bind_addr = "127.0.0.1:${toString adminPort}";
          admin_token = "@env:GARAGE_ADMIN_TOKEN";
        };
      };
    };

    caddy = {
      enable = true;
      virtualHosts =
        {
          ${url} = let
            public = {
              ente = "GET HEAD PUT OPTIONS";
            };
          in {
            useACMEHost = "lhf.pt";
            extraConfig = ''
              @allowed remote_ip 100.64.0.0/10 127.0.0.1
              handle @allowed {
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
        }
        // lib.genAttrs web (_: {
          useACMEHost = "lhf.pt";
          extraConfig = ''
            reverse_proxy :${toString webPort}
          '';
        });
    };
  };

  networking.firewall.allowedTCPPorts = [443];
}
