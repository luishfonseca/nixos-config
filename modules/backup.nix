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
    hooks = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          script = mkOption {
            type = types.package;
            description = "Script to run before backup";
          };
          user = mkOption {
            type = types.str;
            description = "User to run the hook as";
          };
          depends = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Systemd units this hook requires (and waits for)";
          };
        };
      });
      default = {};
      description = "Scripts to run before backup";
    };
    pause = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Units to stop during the backup";
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
        exec borg "$@"
      '')

      (pkgs.writeShellScriptBin "borg-ncdu" ''
        if [ "$(id -u)" -ne 0 ]; then
          echo "borg-ncdu must be run as root" >&2
          exit 1
        fi

        exec ${pkgs.nix}/bin/nix eval --json \
            config#nixosConfigurations."$(hostname)".config.lhf.backup.exclude \
          | ${pkgs.jq}/bin/jq -r '.[] | "--exclude", .' \
          | ${pkgs.findutils}/bin/xargs -o ${pkgs.ncdu}/bin/ncdu /nix/pst
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

    systemd.services =
      (lib.mapAttrs' (name: hook:
        lib.nameValuePair "borgbackup-job-default-hook-${name}" {
          requires = hook.depends;
          after = hook.depends;
          wantedBy = ["borgbackup-job-default.service"];
          before = ["borgbackup-job-default.service"];
          serviceConfig = {
            Type = "oneshot";
            User = hook.user;
            ExecStart = hook.script;
          };
        })
      cfg.hooks)
      // {
        borgbackup-job-default = {
          conflicts = cfg.pause;
          after = cfg.pause;
          onSuccess = cfg.pause;
          onFailure = cfg.pause;
        };
      };
  };
}
