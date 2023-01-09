{ config, options, lib, ... }:

with lib;
let cfg = config.lhf.services.dnsovertlsProxy; in
{
  options.lhf.services.dnsovertlsProxy = {
    enable = mkEnableOption "DNS over TLS proxy";
    name = mkOption {
      type = types.str;
      description = "DNS server name";
    };
    ip = mkOption {
      type = types.str;
      description = "DNS server IP";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      nameservers = [ "127.0.0.53" ];
      dhcpcd.extraConfig = "nohook resolv.conf";
    };

    services.coredns = {
      enable = true;
      config = ''
        . {
            bind 127.0.0.53
            forward . tls://${cfg.ip} {
                tls_servername ${cfg.name}
            }
        }
      '';
    };
  };
}
