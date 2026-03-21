{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.lhf.boot.mutualUnlock;
  port = toString cfg.port;
  fetchScript = pkgs.writeShellScript "luks-key-fetch" ''
    set -euo pipefail
    BOOT=/sysroot/boot

    if [ ! -f "$BOOT/unlock-client.cert" ]; then
      echo "No client cert found, skipping unlock"
      exit 0
    fi

    echo "Requesting unlock key from ${cfg.peer.public}:${port}"
    mkdir -p /run/unlock
    if ${pkgs.curl}/bin/curl -sf --max-time 30 \
      --cacert "$BOOT/unlock-peer.cert" \
      --cert "$BOOT/unlock-client.cert" \
      --key "$BOOT/unlock-client.key" \
      "https://${cfg.peer.public}:${port}/unlock" \
      -o /run/unlock/root.key; then
      chmod 600 /run/unlock/root.key
      echo "Unlock key received, wrote /run/unlock/root.key"
    else
      rm -f /run/unlock/root.key
      echo "Fetch failed, falling back to password prompt"
    fi
  '';
in {
  options.lhf.boot.mutualUnlock = with lib; {
    enable = mkEnableOption "mutual LUKS unlock via mTLS between peers";
    wants = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra systemd units this service depends on (e.g. tailscaled.service).";
    };
    port = mkOption {
      type = types.port;
      default = 9735;
      description = "Port for the key services.";
    };
    ttl = mkOption {
      type = types.int;
      default = 300;
      description = "TTL in seconds for registered keys.";
    };
    self = {
      internal = mkOption {
        type = types.str;
        description = "Internal IP address to listen for registration requests.";
      };
      external = mkOption {
        type = types.str;
        description = "External IP address to listen for key requests.";
      };
      public = mkOption {
        type = types.str;
        default = cfg.self.external;
        description = "External IP address as seen by peer. Override for NAT.";
      };
    };
    peer = {
      internal = mkOption {
        type = types.str;
        description = "Internal IP address to register.";
      };
      public = mkOption {
        type = types.str;
        description = "Public IP address to request keys.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.lhf.boot.disk.encrypt;
        message = "LUKS unlock requires disk encryption.";
      }
    ];

    networking = {
      nftables.enable = true;
      firewall = {
        enable = true;
        extraInputRules = ''
          ip saddr ${cfg.peer.public} tcp dport ${port} accept
          ip saddr ${cfg.peer.internal} tcp dport ${port} accept
        '';
      };
    };

    systemd.services = let
      deps =
        [
          "network-online.target"
          "wait-for-ip@${cfg.self.internal}.service"
        ]
        ++ cfg.wants;
    in {
      "wait-for-ip@" = {
        description = "Wait for IP %i to be assigned";
        after = ["network.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart =
            pkgs.writeShellScript "wait-for-ip" ''
              until ${pkgs.iproute2}/bin/ip -br -4 addr show | grep -q "$1"; do
                sleep 1
              done
            ''
            + " %i";
          TimeoutStartSec = 120;
        };
      };

      luks-key-service = {
        wantedBy = ["multi-user.target"];
        wants = deps;
        after = deps;
        serviceConfig = {
          ExecStart = lib.concatStringsSep " " [
            "${pkgs.lhf.luks-key-service}/bin/luks-key-service"
            "--unlock-addr ${cfg.self.external}"
            "--register-addr ${cfg.self.internal}"
            "--port ${port}"
            "--cert ${config.sops.secrets.unlock-server-cert.path}"
            "--key ${config.sops.secrets.unlock-server-key.path}"
            "--ttl ${toString cfg.ttl}"
          ];
          Restart = "on-failure";
        };
      };

      luks-reboot-prepare = {
        wantedBy = ["multi-user.target"];
        wants = deps;
        after = deps;
        unitConfig.RequiresMountsFor = ["/boot" "/recovery"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = lib.concatStringsSep " " [
            "${pkgs.lhf.luks-reboot-prepare}/bin/luks-reboot-prepare"
            "--peer-internal ${cfg.peer.internal}"
            "--self-public ${cfg.self.public}"
            "--port ${port}"
          ];
        };
      };
    };

    boot.initrd = {
      luks.devices.root_crypt.keyFile = "/run/unlock/root.key";

      systemd = {
        initrdBin = [pkgs.curl];
        storePaths = [fetchScript];
        services.luks-key-fetch = {
          before = ["systemd-cryptsetup@root_crypt.service"];
          after = ["systemd-networkd-wait-online.service"];
          wants = ["systemd-networkd-wait-online.service"];
          wantedBy = ["initrd.target"];
          unitConfig = {
            DefaultDependencies = false;
            RequiresMountsFor = "/sysroot/boot";
          };
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = fetchScript;
          };
        };
      };
    };
  };
}
