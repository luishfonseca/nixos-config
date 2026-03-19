{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.lhf.boot.tailscale;
  tsPkg = config.services.tailscale.package;
in {
  options.lhf.boot.tailscale = with lib; {
    enable = mkEnableOption "Tailscale-based remote LUKS unlock in initrd";
    authKeyExpiry = mkOption {
      type = types.int;
      default = 600;
      description = "Authkey expiry in seconds.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.lhf.boot.disk.encrypt;
        message = "Tailscale initrd unlock requires disk encryption.";
      }
    ];

    fileSystems = {
      "/boot".neededForBoot = true;
      "/nix".options = ["x-systemd.device-timeout=0"];
    };

    boot.initrd = {
      availableKernelModules = ["tun" "nft_chain_nat"];
      systemd = {
        packages = [tsPkg];
        initrdBin = [pkgs.iptables pkgs.iproute2 tsPkg];
        extraBin.ping = "${pkgs.iputils}/bin/ping";
        contents."/etc/resolv.conf".text = "nameserver 1.1.1.1\n";

        network = {
          enable = true;
          wait-online.anyInterface = true;
          networks."10-dhcp" = {
            matchConfig.Name = "en*";
            networkConfig.DHCP = "yes";
          };
          networks."50-tailscale" = {
            matchConfig.Name = config.services.tailscale.interfaceName;
            linkConfig = {
              Unmanaged = true;
              ActivationPolicy = "manual";
            };
          };
        };

        services = {
          tailscaled = {
            wantedBy = ["initrd.target"];
            wants = ["systemd-networkd-wait-online.service"];
            after = ["systemd-networkd-wait-online.service"];
            unitConfig.DefaultDependencies = false;
            serviceConfig.Environment = [
              "PORT=${toString config.services.tailscale.port}"
              ''"FLAGS=--tun ${lib.escapeShellArg config.services.tailscale.interfaceName}"''
            ];
          };

          tailscale-up = {
            wantedBy = ["initrd.target"];
            before = ["systemd-cryptsetup@root_crypt.service"];
            wants = ["tailscaled.service"];
            after = ["tailscaled.service"];
            unitConfig = {
              DefaultDependencies = false;
              RequiresMountsFor = "/sysroot/boot";
            };
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              TimeoutStartSec = 60;
              ExecStart = lib.concatStringsSep " " [
                "${tsPkg}/bin/tailscale up"
                "--authkey=file:/sysroot/boot/tailscale-initrd-authkey"
                "--hostname=${config.networking.hostName}-init"
                "--accept-dns=false"
                "--ssh"
              ];
            };
          };
        };

        tmpfiles.settings."50-tailscale"."/var/run".L.argument = "/run";
      };
    };

    environment.systemPackages = [pkgs.lhf.write-initrd-tailscale-key];

    systemd.services.write-initrd-tailscale-key = {
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      after = ["network-online.target"];
      unitConfig.RequiresMountsFor = "/boot";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        EnvironmentFile = config.sops.secrets.tailscale-auth-key-init-env.path;
        ExecStop = "${pkgs.lhf.write-initrd-tailscale-key}/bin/write-initrd-tailscale-key ${toString cfg.authKeyExpiry}";
      };
    };
  };
}
