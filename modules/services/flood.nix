{
  config,
  options,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.lhf.services.flood;
in {
  options.lhf.services.flood = {
    enable = mkEnableOption "Flood";

    bind = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "Address to bind flood to";
    };
    port = mkOption {
      type = types.int;
      default = 9092;
      description = "Port to run flood on";
    };

    user = mkOption {
      type = types.str;
      default = "flood";
      description = "User to run flood as";
    };
    group = mkOption {
      type = types.str;
      default = "flood";
      description = "Group to run flood as";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/flood";
      description = "Directory to store flood data in";
    };

    transmission = {
      enable = mkEnableOption "Transmission Backend";
      url = mkOption {
        type = types.str;
        default = "http://localhost:9091/transmission/rpc";
        description = "URL to the transmission RPC endpoint";
      };
      user = mkOption {
        type = types.str;
        default = "";
        description = "Username to use for transmission";
      };
      pass = mkOption {
        type = types.str;
        default = "";
        description = "Password to use for transmission";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.flood = let
      backendOpts =
        if cfg.transmission.enable
        then "--auth none --trurl ${cfg.transmission.url} --truser ${cfg.transmission.user} --trpass ${cfg.transmission.pass}"
        else "";
    in {
      description = "Flood";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${pkgs.flood}/bin/flood -h ${cfg.bind} -p ${toString cfg.port} -d ${cfg.dataDir} ${backendOpts}";
        Restart = "always";
        RestartSec = 5;
      };
    };

    users.users.flood = {
      isSystemUser = true;
      home = cfg.dataDir;
      createHome = true;
      group = "flood";
    };
    users.groups.flood = {};

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0755 ${cfg.user} ${cfg.group} - -"
    ];
  };
}
