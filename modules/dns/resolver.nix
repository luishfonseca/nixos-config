{
  config,
  lib,
  ...
}: let
  cfg = config.lhf.dnsResolver;
in {
  options.lhf.dnsResolver = with lib; {
    enable = mkEnableOption "custom dns resolver";
    magicDNS = {
      enable = mkEnableOption "using tailnet to resolve internal domains";
      internalDomain = mkOption {
        type = types.str;
        description = "The internal domain name";
      };
      tailnet = mkOption {
        type = types.str;
        description = "The tailnet domain name";
      };
    };
    upstream = {
      name = mkOption {
        type = types.str;
        description = "The upstream dns domain name";
      };
      ip = mkOption {
        type = types.str;
        description = "The upstream dns server ip";
      };
    };
    fallbacks = mkOption {
      type = types.listOf types.str;
      description = "The fallback dns servers";
      default = ["1.1.1.1" "1.0.0.1"];
    };
  };

  config = let
    escape = lib.replaceStrings ["."] ["\."];
  in
    lib.mkIf cfg.enable {
      networking.dhcpcd.extraConfig = "nohook resolv.conf";

      environment.etc."resolv.conf" = {
        text =
          ''
            nameserver 127.0.0.1
            ${lib.concatStringsSep "\n" (map (ip: "nameserver ${ip}") cfg.fallbacks)}
            options edns0 trusted-ad
          ''
          + lib.optionalString cfg.magicDNS.enable ''
            search ${cfg.magicDNS.internalDomain}
          '';
        mode = "0644";
      };

      services.resolved.enable = false;

      services.coredns = {
        enable = true;
        config =
          (lib.optionalString cfg.magicDNS.enable ''
            ${cfg.magicDNS.internalDomain} {
              rewrite name suffix ${cfg.magicDNS.internalDomain} ${cfg.magicDNS.tailnet} answer auto
              forward . 100.100.100.100
            }

            100.in-addr.arpa {
              rewrite stop {
                name suffix arpa arpa
                answer name auto
                answer value (.*)\.${escape cfg.magicDNS.tailnet} {1}.${escape cfg.magicDNS.internalDomain}
              }
              forward . 100.100.100.100
            }
          '')
          + ''
            . {
              forward . tls://${cfg.upstream.ip} {
                tls_servername ${cfg.upstream.name}
              }
            }
          '';
      };
    };
}
