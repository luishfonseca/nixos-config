{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.lhf.localDB;
in {
  options.lhf.localDB = with lib; {
    enable = mkEnableOption "local database";
    port = mkOption {
      type = types.port;
      default = 5432;
    };
    dbs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Databases to create";
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      settings.port = cfg.port;
      ensureDatabases = cfg.dbs;
      ensureUsers =
        builtins.map (name: {
          inherit name;
          ensureDBOwnership = true;
        })
        cfg.dbs;
    };

    lhf.backup = {
      exclude = ["/nix/pst${config.services.postgresql.dataDir}"];
      hooks.postgresql = {
        user = "postgres";
        depends = ["postgresql.target"];
        script = pkgs.writeShellScript "pre-backup" ''
          set -e -o pipefail

          umask 0077
          mkdir -p /var/lib/postgresql/backup
          cd /var/lib/postgresql/backup

          if [ -e db.bak ]; then
            rm -f db.bak.prev
            mv db.bak db.bak.prev
          fi

          ${config.services.postgresql.package}/bin/pg_dumpall > db.bak.tmp
          mv db.bak.tmp db.bak
        '';
      };
    };
  };
}
