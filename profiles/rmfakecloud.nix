{config, ...}: let
  port = 3123;
  name = "rmfakecloud";
  url = "https://${name}.${config.lhf.tailscale.tailnet}";
in {
  imports = [
    ./caddy-tailscale.nix
  ];

  systemd.services.rmfakecloud = {
    requires = ["vault.service"];
    after = ["vault.service"];
    serviceConfig = {
      SupplementaryGroups = ["box"];
      BindPaths = ["/mnt/vault/${name}"];
      ReadWritePaths = ["/mnt/vault/${name}"];
      MountFlags = "shared";
    };
  };

  services = {
    rmfakecloud = {
      enable = true;
      inherit port;
      extraSettings.DATADIR = "/mnt/vault/${name}";
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
