{
  config,
  pkgs,
  lib,
  publicKeys,
  ...
}: let
  cfg = config.lhf.zfs.fde.tpm.remote;
in {
  options.lhf.zfs.fde.tpm.remote = with lib; {
    enable = mkEnableOption "remote unlocking";
    # TODO: wireless - write script to dump ssid:psk from nmcli to a wpa_supplicant.conf in rd_shared on shutdown
    tailscale = mkEnableOption "tailscale in initrd";
    # TODO: tailscale.enforce - only allow ssh connections from tailscale
    authorizedKeys = mkOption {
      type = types.listOf types.str;
      description = "Authorized keys for remote unlocking";
      default = publicKeys.users;
    };
  };

  config =
    lib.mkIf (
      cfg.enable
      && config.lhf.zfs.enable
      && config.lhf.zfs.fde.enable
      && config.lhf.zfs.fde.tpm.enable
    ) (lib.mkMerge [
      {
        # Create a volume to share data between initrd and the booted system
        # It unlocks just with TPM and no password
        disko.devices.zpool.zroot.datasets.rd_shared_vol = {
          type = "zfs_volume";
          size = "64M";
          content = {
            name = "rd_shared_crypt";
            type = "luks";
            passwordFile = "/keys/rd_shared_vol.key";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/local/rd_shared";
              mountOptions = ["x-systemd.requires-mounts-for=/local"];
            };
            preCreateHook = lib.lhf.genKey "rd_shared_vol.key";
            postCreateHook = ''
              systemd-cryptenroll /dev/zvol/zroot/rd_shared_vol --unlock-key-file=/keys/rd_shared_vol.key --tpm2-device=auto --tpm2-pcrs=
            '';
          };
        };

        boot.initrd = {
          availableKernelModules = ["igb" "igc" "e1000e" "r8169" "virtio_pci" "virtio_net"];

          luks.devices.rd_shared_crypt = {
            # See Elvish's comment in https://discourse.nixos.org/t/a-modern-and-secure-desktop-setup/41154/17
            crypttabExtraOpts = ["tpm2-device=auto" "tpm2-measure-pcr=yes"];
            device = "/dev/zvol/zroot/rd_shared_vol";
          };

          network = {
            enable = true;
            # flushBeforeStage2 = true;
            ssh = {
              inherit (cfg) authorizedKeys;
              enable = true;
              ignoreEmptyHostKeys = true;
              extraConfig = ''
                HostKey /rd_shared/ssh_host_ed25519_key
              ''; # When cfg.enable deploy-anywhere places the key in rd_shared, and symlinks it to /local/etc/ssh
            };
          };

          systemd = {
            network =
              config.systemd.network
              // {
                # TODO: this still doesn't work
                # networks."99-fallback" = {
                #   name = "*";
                #   DHCP = "yes";
                # };
              };

            contents."/etc/fstab".text = ''
              /dev/mapper/rd_shared_crypt /rd_shared ext4 defaults 0 2
            '';

            users.root.shell = "${pkgs.systemd}/bin/systemd-tty-ask-password-agent";

            services = {
              "zfs-import-zroot-bare" = {
                requiredBy = ["systemd-cryptsetup@rd_shared_crypt.service"];
                before = ["systemd-cryptsetup@rd_shared_crypt.service"];
              };

              sshd = {
                unitConfig.RequiresMountsFor = ["/rd_shared"];
                wantedBy = ["systemd-cryptsetup@key_crypt.service"];
                before = ["systemd-cryptsetup@key_crypt.service"];
              };
            };
          };
        };
      }
      (lib.mkIf cfg.tailscale {
        disko.devices.zpool.zroot.datasets.rd_shared_vol.content.content.postMountHook = lib.mkBefore ''
          mkdir -p /mnt/local/rd_shared/tailscale
        '';

        systemd.services.tailscaled.serviceConfig.Restart = "on-success";

        services.tailscale.patch = {
          stateDir = "/local/rd_shared/tailscale";
          depends = ["/local/rd_shared"];
        };

        boot.initrd = {
          availableKernelModules = ["tun" "nft_chain_nat"];
          services.resolved.enable = true;

          systemd = {
            initrdBin = with pkgs; [iptables iproute2 iputils tailscale];
            packages = with pkgs; [tailscale];

            contents."/etc/fstab".text = ''
              /rd_shared/tailscale /var/lib/tailscale none bind,x-systemd.requires-mounts-for=/rd_shared
            '';

            tmpfiles.settings."10-tailscale" = {
              "/var/run".L.argument = "/run";
              "/etc/resolv.conf".f.argument = "nameserver 1.1.1.1"; # use cloudflare DNS on initrd
            };

            network.networks."50-tailscale" = {
              matchConfig.Name = config.services.tailscale.interfaceName;
              linkConfig = {
                Unmanaged = true;
                ActivationPolicy = "manual";
              };
            };

            services.tailscaled = {
              inherit (config.systemd.services.tailscaled) serviceConfig unitConfig;
              wantedBy = ["systemd-cryptsetup@key_crypt.service"];
              before = ["systemd-cryptsetup@key_crypt.service"];
            };
          };
        };
      })
    ]);
}
