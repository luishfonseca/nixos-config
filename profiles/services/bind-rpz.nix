{
  config,
  pkgs,
  lib,
  ...
}: let
  allowed = ["100.64.0.0/10"];
in {
  persist.system.directories = [config.services.bind.directory];
  lhf.backup.exclude = ["/nix/pst${config.services.bind.directory}/dynamic"];

  systemd.tmpfiles.settings."10-bind-rpz" = {
    "${config.services.bind.directory}/dynamic".d = {
      user = "named";
      group = "named";
      mode = "0750";
    };
    "${config.services.bind.directory}/dynamic/rpz".C = {
      user = "named";
      group = "named";
      mode = "0640";
      argument = toString (pkgs.writeText "rpz" ''
        $TTL 5
        @ SOA localhost. root.localhost. (1 1d 1h 30d 5)
          NS  localhost.
      '');
    };
  };

  sops.secrets.bind-ddns-key.owner = "named";

  services.bind = {
    enable = true;

    listenOn = allowed;
    cacheNetworks = allowed;

    forward = "only";
    forwarders = [
      "1.1.1.1 port 853 tls cf"
      "1.0.0.1 port 853 tls cf"
      "2606:4700:4700::1111 port 853 tls cf"
      "2606:4700:4700::1001 port 853 tls cf"
    ];

    zones.rpz = {
      master = true;
      file = "${config.services.bind.directory}/dynamic/rpz";
      slaves = ["key ddns"];
      extraConfig = ''
        update-policy { grant ddns zonesub CNAME; };
      '';
    };
    extraOptions = ''
      allow-recursion { ${lib.concatMapStrings (ip: "${ip}; ") allowed}};
      auth-nxdomain yes;
      dnssec-validation no;
      response-policy {
        zone "rpz";
      } max-policy-ttl 5;
    '';
    extraConfig = ''
      zone "tail9db2a.ts.net" {
          type forward;
          forward only;
          forwarders { 100.100.100.100; };
      };

      include "${config.sops.secrets.bind-ddns-key.path}";
      tls cf { remote-hostname "one.one.one.one"; };
    '';
  };
}
