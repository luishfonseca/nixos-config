{
  config,
  pkgs,
  lib,
  ...
}: let
  port = 3123;
  name = "rmfakecloud";
  url = "https://${name}.${config.lhf.tailscale.tailnet}";

  package = let
    rev = "4f21ea9860f849057d621eefdafeb65e50a632c9";
    src = pkgs.fetchFromGitHub {
      inherit rev;
      owner = "nemunaire";
      repo = "rmfakecloud";
      hash = "sha256-LZrJrmL8LqZVjgVTSO//uQBeGkNYUEPZZ2DMRih9OTQ=";
    };
  in
    pkgs.rmfakecloud.overrideAttrs (old: rec {
      inherit src;
      version = rev;
      vendorHash = "sha256-yCDsi7ExNXIw587StCAnXPM9FoLVQJmCehEOT8phL0k=";
      env =
        old.env
        // {
          pnpmDeps = pkgs.fetchPnpmDeps {
            inherit (old) pname;
            inherit src version;
            sourceRoot = "${src.name}/ui";
            pnpmLock = "${src}/ui/pnpm-lock.yaml";
            inherit (old.env.pnpmDeps) pnpm fetcherVersion;
            hash = "sha256-SqEcvW6k3JjJHI4nhIt0KCRuWv096yY7CqyOgAzuqbI=";
          };
        };
    });
in {
  imports = [
    ./caddy-tailscale.nix
  ];

  systemd.services.rmfakecloud = {
    requires = ["garage.service"];
    after = ["garage.service"];
  };

  services = {
    rmfakecloud = {
      inherit package port;
      enable = true;
      extraSettings = {
        RM_HTTPS_COOKIE = "true";
        
        # sudo garage key create rmfakecloud
        # sudo garage bucket create rmfakecloud
        # sudo garage bucket allow --read --write --owner rmfakecloud --key rmfakecloud
        # sudo garage bucket allow --read rmfakecloud --key admin
        AWS_ENDPOINT_URL = "https://s3.${config.lhf.tailscale.tailnet}";
        AWS_REGION = "garage";
        S3_PATH_STYLE = "true";
        S3_BUCKET_NAME = "rmfakecloud";
        AWS_ACCESS_KEY_ID = "GK7c6f8c1e0f0a9f30d08a0a01";
      };
      environmentFile = config.sops.secrets.rmfakecloud-env.path;
      storageUrl = "https://local.appspot.com";
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
