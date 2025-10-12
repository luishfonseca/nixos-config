{
  inputs,
  config,
  pkgs,
  lib,
  publicKeys,
  ...
}: let
  cfg = config.lhf.zfs.fde;
in {
  options.lhf.zfs.fde = with lib; {
    enable = mkEnableOption "full-disk encryption";
    tpm = {
      enable = mkEnableOption "TPM";
      remote = {
        enable = mkEnableOption "remote unlocking";
        tailscale = mkEnableOption "tailscale in initrd";
        authorizedKeys = mkOption {
          type = types.listOf types.str;
          description = "Authorized keys for remote unlocking";
          default = publicKeys.users;
        };
      };
    };
  };

  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  config = let
    generateKey = key: ''
      mkdir -p /keys
      od -Anone -x -N 32 /dev/random | tr -d [:blank:] | tr -d '\n' > /keys/${key}
      chmod 600 /keys/${key}
    '';

    enrollKeys = ''
      keys=$(ls /keys)
      for f in $keys; do
        mv "/keys/$f" /tmp
      done
      mount /dev/mapper/keyvol /keys
      for f in $keys; do
        mv "/tmp/$f" /keys
      done

      printf '\e[1;33m%s\n\e[0m' \
        "Make sure to BACKUP the contents of /keys"

      ${
        lib.optionalString cfg.tpm.enable ''
          if [ $(${pkgs.lhf.sbctl}/bin/sbctl status --json | ${pkgs.jq}/bin/jq .setup_mode) = false ]; then
            printf '\e[1;31m%s\n%s\n\e[0m' \
              "WARNING: Secure Boot Setup Mode is not enabled!" \
              "You will need to enroll the keys manually."
          fi

          printf '\e[1;36m%s\n%s\n%s\n%s\n\e[0m' \
            "For TPM unlocking to be secure, ensure the following:" \
            "  - The BIOS has a password set" \
            "  - Secure Boot is enabled" \
            "  - Disks are bound to PCR7 (run \`tpm-lockup\` after reboot)"
        ''
      }

      read -p "Press enter to continue..."

      systemd-cryptenroll /dev/zvol/zroot/keyvol --unlock-key-file=/keys/keyvol_recovery.key ${
        if cfg.tpm.enable
        then "--tpm2-device=auto --tpm2-pcrs="
        else "--password"
      }

      ${
        lib.optionalString cfg.tpm.enable ''
          mkdir -p /keys/sbctl
          ${pkgs.lhf.sbctl}/bin/sbctl create-keys
          if [ $(${pkgs.lhf.sbctl}/bin/sbctl status --json | ${pkgs.jq}/bin/jq .setup_mode) = true ]; then
            ${pkgs.lhf.sbctl}/bin/sbctl enroll-keys -m
          fi
        ''
      }

      chmod -R 600 /keys
    '';
  in
    lib.mkIf (config.lhf.zfs.enable && cfg.enable) (lib.mkMerge [
      {
        fileSystems."/keys" = {
          device = "/dev/mapper/keyvol";
          options = ["defaults" "ro"];
        };

        boot = {
          loader.systemd-boot.enable = true;
          initrd = {
            availableKernelModules = ["ext4"];

            systemd = {
              contents."/etc/fstab".text = ''
                /dev/mapper/keyvol /keys ext4 defaults,nofail,x-systemd.device-timeout=0,ro 0 2
              '';

              services = {
                "zfs-import-zroot".enable = false; # disable default zfs import

                "zfs-import-zroot-bare" = {
                  enable = true;
                  wants = ["systemd-udev-settle.service"];
                  after = ["systemd-udev-settle.service"];
                  unitConfig.DefaultDependencies = false;
                  serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${config.boot.zfs.package}/bin/zpool import -f -N zroot";
                    RemainAfterExit = true;
                  };
                };

                zroot-load-key = {
                  enable = true;
                  requires = ["zfs-import-zroot-bare.service"];
                  after = ["zfs-import-zroot-bare.service"];
                  wantedBy = ["sysroot.mount"];
                  before = ["sysroot.mount"];
                  unitConfig = {
                    RequiresMountsFor = ["/keys"];
                    DefaultDependencies = false;
                  };
                  serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${config.boot.zfs.package}/bin/zfs load-key zroot/root";
                    RemainAfterExit = true;
                  };
                };
              };
            };

            luks.devices.keyvol.device = "/dev/zvol/zroot/keyvol";
          };
        };

        disko.devices.zpool.zroot = {
          datasets = {
            root = {
              options = {
                encryption = "aes-256-gcm";
                keyformat = "hex";
                keylocation = "file:///keys/zfs.key";
              };
              preCreateHook = generateKey "zfs.key";
            };
            keyvol = {
              type = "zfs_volume";
              size = "64M";
              content = {
                name = "keyvol";
                type = "luks";
                passwordFile = "/keys/keyvol_recovery.key";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/keys";
                };
                preCreateHook = generateKey "keyvol_recovery.key";
                postCreateHook = enrollKeys;
              };
            };
          };
        };
      }
      (lib.mkIf cfg.tpm.enable (lib.mkMerge [
        {
          boot = {
            initrd = {
              systemd.tpm2.enable = true;
              luks.devices.keyvol.crypttabExtraOpts = ["tpm2-device=auto"];
            };

            loader.systemd-boot.enable = lib.mkForce false;

            lanzaboote = {
              enable = true;
              pkiBundle = "/keys/sbctl";
            };
          };

          environment.systemPackages = with pkgs; [lhf.sbctl lhf.tpm-lockup];
        }
        (lib.mkIf cfg.tpm.remote.enable (lib.mkMerge [
          {
            fileSystems."/ssh".device = "/dev/mapper/sshvol";

            boot.initrd = {
              availableKernelModules = ["igb"];

              systemd = {
                inherit (config.systemd) network;

                contents."/etc/fstab".text = ''
                  /dev/mapper/sshvol /ssh ext4 defaults 0 2
                '';

                tmpfiles.settings."50-ssh-host-keys" = {
                  "/etc/ssh/ssh_host_ed25519_key".C = {
                    mode = "0600";
                    argument = "/ssh/ssh_host_ed25519_key";
                  };
                  "/etc/ssh/ssh_host_rsa_key".C = {
                    mode = "0600";
                    argument = "/ssh/ssh_host_rsa_key";
                  };
                };

                services.systemd-tmpfiles-setup.before = ["sshd.service"];
              };

              luks.devices = {
                sshvol = {
                  device = "/dev/zvol/zroot/sshvol";
                  crypttabExtraOpts = ["tpm2-device=auto"];
                };
                keyvol.crypttabExtraOpts = ["nofail"];
              };

              network.ssh = {
                inherit (cfg.tpm.remote) authorizedKeys;
                enable = true;
                ignoreEmptyHostKeys = true;
              };
            };

            systemd.tmpfiles.settings."10-ssh-host-keys" = {
              "/etc/ssh/ssh_host_ed25519_key".C = {
                mode = "0600";
                argument = "/ssh/ssh_host_ed25519_key";
              };
              "/etc/ssh/ssh_host_ed25519_key.pub".C = {
                mode = "0644";
                argument = "/ssh/ssh_host_ed25519_key.pub";
              };
              "/etc/ssh/ssh_host_rsa_key".C = {
                mode = "0600";
                argument = "/ssh/ssh_host_rsa_key";
              };
              "/etc/ssh/ssh_host_rsa_key.pub".C = {
                mode = "0644";
                argument = "/ssh/ssh_host_rsa_key.pub";
              };
            };

            disko.devices.zpool.zroot.datasets.sshvol = {
              type = "zfs_volume";
              size = "64M";
              content = {
                name = "sshvol";
                type = "luks";
                passwordFile = "/keys/sshvol_recovery.key";
                content = {
                  type = "filesystem";
                  format = "ext4";
                };
                preCreateHook = generateKey "sshvol_recovery.key";
                postCreateHook = ''
                  mkdir -p /ssh
                  mount /dev/mapper/sshvol /ssh
                  ssh-keygen -f /ssh/ssh_host_ed25519_key -t ed25519 -N "" -C "root@${config.networking.hostName}"
                  ssh-keygen -f /ssh/ssh_host_rsa_key -t rsa -b 4096 -N "" -C "root@${config.networking.hostName}"
                  systemd-cryptenroll /dev/zvol/zroot/sshvol --unlock-key-file=/keys/sshvol_recovery.key --tpm2-device=auto --tpm2-pcrs=
                  umount /ssh
                '';
              };
            };
          }
          (lib.mkIf cfg.tpm.remote.tailscale {
            fileSystems."/var/lib/tailscale" = {
              device = "/ssh/var/lib/tailscale";
              depends = ["/ssh"];
              fsType = "none";
              options = ["bind"];
            };

            boot.initrd = {
              availableKernelModules = ["tun" "nft_chain_nat"];
              services.resolved.enable = true;

              systemd = {
                initrdBin = with pkgs; [iptables iproute2 iputils tailscale];
                packages = with pkgs; [tailscale];

                contents."/etc/fstab".text = ''
                  /ssh/var/lib/tailscale /var/lib/tailscale none bind,x-systemd.requires-mounts-for=/ssh/var/lib/tailscale
                '';

                tmpfiles.settings."50-tailscale"."var/run".L.argument = "/run";

                network.networks."50-tailscale" = {
                  matchConfig = {
                    Name = "tun0";
                  };
                  linkConfig = {
                    Unmanaged = true;
                    ActivationPolicy = "manual";
                  };
                };

                services.tailscaled = {
                  wantedBy = ["initrd.target"];
                  serviceConfig.Environment = [
                    "PORT=0"
                    ''"FLAGS=--tun tun0"''
                  ];
                };
              };
            };

            services.tailscale.enable = true;
          })
        ]))
      ]))
    ]);
}
