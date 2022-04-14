{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.rnl.networking; in {
  options.lhf.rnl.networking = with types; {
    enable = mkEnableOption "RNL Network Config";
    enableOnBoot = mkEnableOption "Network during Boot";
    interface = mkOption { type = str; };
    lastOctet = mkOption {
      type = addCheck int (n: n >= 0 && n <= 255);
    };
  };

  config = mkIf cfg.enable (mkMerge [{
    networking = {
      interfaces."${cfg.interface}" = {
        ipv4.addresses = [{
          address = "193.136.164.${toString cfg.lastOctet}";
          prefixLength = 27;
        }];
        ipv6.addresses = [{
          address = "2001:690:2100:82::${toString cfg.lastOctet}";
          prefixLength = 64;
        }];
      };

      defaultGateway = { address = "193.136.164.222"; inherit (cfg) interface; };
      defaultGateway6 = { address = "2001:690:2100:82::ffff:1"; inherit (cfg) interface; };

      nameservers = [
        "193.136.164.1"
        "193.136.164.2"
        "2001:690:2100:80::1"
        "2001:690:2100:80::2"
      ];

      domain = "rnl.tecnico.ulisboa.pt";

      search = [
        "rnl.tecnico.ulisboa.pt"
        "tecnico.ulisboa.pt"
      ];
    };
  }
  (mkIf cfg.enableOnBoot {
    boot.kernelParams = [
      "ip=193.136.164.${toString cfg.lastOctet}::193.136.164.222:255.255.255.224:${config.networking.hostName}:${cfg.interface}:off"
    ];
    boot.initrd = {
      network.enable = true;
      kernelModules = [ "r8169" ];
    };
  })]);
}
