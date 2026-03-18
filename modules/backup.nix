{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.lhf.backup;
in {
  options.lhf.backup = with lib; {
    enable = mkEnableOption "borg backup to remote host";
    repo = mkOption {
      type = types.str;
      description = "Borg repository path";
    };
    extraPaths = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional paths to back up besides /nix/pst";
    };
    exclude = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["/nix/pst/var/lib/docker"];
      description = "Paths to exclude from backup";
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
        export BORG_REPO="${cfg.repo}"

        # Auto-prepend :: to bare archive names (detected by ISO timestamp)
        args=()
        for arg in "$@"; do
          if [[ "$arg" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}T && "$arg" != ::* && "$arg" != /* ]]; then
            args+=("::$arg")
          else
            args+=("$arg")
          fi
        done
        exec borg "''${args[@]}"
      '')
    ];

    services.borgbackup.jobs.default = {
      inherit (cfg) repo exclude;
      paths = ["/nix/pst"] ++ cfg.extraPaths;
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
