{
  config,
  pkgs,
  ...
}: let
  s3Port = 3900;
  rpcPort = 3901;
  adminPort = 3903;
  name = "s3";
  url = "https://${name}.${config.lhf.tailscale.tailnet}";
in {
  imports = [
    ./caddy-tailscale.nix
  ];

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
          api_bind_addr = "127.0.0.1:${toString s3Port}";
          s3_region = "garage";
        };

        admin = {
          api_bind_addr = "127.0.0.1:${toString adminPort}";
          admin_token = "@env:GARAGE_ADMIN_TOKEN";
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
        reverse_proxy :${toString s3Port}
      '';
    };
  };
}
