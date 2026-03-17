{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.lhf.backup;
  hostname = config.networking.hostName;
  repo = "borg-${hostname}@${cfg.host}:/mnt/box/borg/${hostname}";
in {
  options.lhf.backup = with lib; {
    enable = mkEnableOption "borg backup to remote host";
    host = mkOption {
      type = types.str;
      description = "Backup server hostname";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "borg-repo" ''
        if [ "$(id -u)" -ne 0 ]; then
          echo "borg-repo must be run as root (secrets are root-readable)" >&2
          exit 1
        fi

        export BORG_RSH="ssh -i ${config.sops.secrets.ssh_host_ed25519.path}"
        export BORG_PASSCOMMAND="cat ${config.sops.secrets.borg-passphrase.path}"
        export BORG_REPO="${repo}"
        exec borg "$@"
      '')
    ];

    services.borgbackup.jobs.default = {
      inherit repo;
      paths = ["/nix/pst"];
      encryption = {
        mode = "repokey";
        passCommand = "cat ${config.sops.secrets.borg-passphrase.path}";
      };
      environment.BORG_RSH = "ssh -i ${config.sops.secrets.ssh_host_ed25519.path}";
      compression = "auto,zstd,16";
      startAt = "daily";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
    };
  };
}
