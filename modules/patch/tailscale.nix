{
  config,
  lib,
  ...
}: let
  cfg = config.services.tailscale.patch;
in {
  options.services.tailscale.patch = with lib; {
    stateDir = mkOption {
      type = types.str;
      default = "/local/var/lib/tailscale";
      description = "Directory to store tailscale state, will be bound to /var/lib/tailscale";
    };
    depends = mkOption {
      type = types.listOf types.str;
      default = ["/local"];
      description = "List of mount points that must be mounted before mounting the stateDir";
    };
  };

  config = lib.mkIf config.services.tailscale.enable {
    fileSystems."/var/lib/tailscale" = {
      inherit (cfg) depends;
      device = cfg.stateDir;
      fsType = "none";
      options = ["bind"];
    };

    systemd.services.tailscaled = {
      unitConfig.RequiresMountsFor = ["/var/lib/tailscale"];
    };
  };
}
