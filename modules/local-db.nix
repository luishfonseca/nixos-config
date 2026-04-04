{
  lib,
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
  };
}
