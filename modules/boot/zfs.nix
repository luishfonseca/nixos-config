{
  inputs,
  config,
  utils,
  pkgs,
  lib,
  ...
}: let
  cfg = config.lhf.boot.zfs;

  sbctl = pkgs.sbctl.override {
    databasePath = "/keyvol/secureboot";
  };

  keys =
    [
      "zfs.key"
      "keyvol_recovery.key"
    ]
    ++ (
      if cfg.encryption.tpm.remote.enable
      then ["sshvol_recovery.key"]
      else []
    );

  generateKeys = ''
    genkey() {
      od -Anone -x -N 32 /dev/random | tr -d [:blank:] | tr -d '\n' > $1
      chmod 600 $1
    }

    if [ ! -f /tmp/.generated ]; then
      ${lib.concatStringsSep "\n" (map (key: "genkey /tmp/${key}") keys)}
      touch /tmp/.generated
    fi
  '';

  enrollKeys = ''
    mkdir -p /keyvol
    mount /dev/mapper/keyvol /keyvol

    ${lib.concatStringsSep "\n" (map (key: "cp /tmp/${key} /keyvol") keys)}
    chmod -R 600 /keyvol

    printf '\e[1;33m%s\n${lib.concatMapStrings (_: "%s\\n") (lib.range 1 (builtins.length keys))}%s\n\e[0m' \
      "The following key files were created:" \
      ${lib.concatStringsSep "\n" (map (key: "\"  - /keyvol/${key}\" \\") keys)}
      "Make sure to BACKUP the keys!!!"

    ${lib.optionalString cfg.encryption.tpm.enable ''
      if [ $(${sbctl}/bin/sbctl status --json | ${pkgs.jq}/bin/jq .setup_mode) = false ]; then
        printf '\e[1;31m%s\n%s\n\e[0m' \
          "WARNING: Secure Boot Setup Mode is not enabled!" \
          "You will need to enroll the keys manually."
      fi

      printf '\e[1;36m%s\n%s\n%s\n%s\n\e[0m' \
        "For TPM unlocking to be secure, ensure the following:" \
        "  - The BIOS has a password set" \
        "  - Secure Boot is enabled" \
        "  - Disks are bound to PCR7 (run \`tpm-lockup\` after reboot)"
    ''}

    read -p "Press enter to continue"

    ${
      if cfg.encryption.tpm.enable
      then ''
        systemd-cryptenroll /dev/zvol/zroot/keyvol --unlock-key-file=/keyvol/keyvol_recovery.key --tpm2-device=auto --tpm2-pcrs=

        ${sbctl}/bin/sbctl create-keys
        if [ $(${sbctl}/bin/sbctl status --json | ${pkgs.jq}/bin/jq .setup_mode) = true ]; then
          ${sbctl}/bin/sbctl enroll-keys -m
        fi
      ''
      else ''
        systemd-cryptenroll /dev/zvol/zroot/keyvol --unlock-key-file=/keyvol/keyvol_recovery.key --password
      ''
    }
  '';

  generateHostKeys = ''
    mkdir -p /sshvol
    mount /dev/mapper/sshvol /sshvol

    ssh-keygen -f /sshvol/ssh_host_ed25519_key -t ed25519 -N "" -C "root@${config.networking.hostName}"
    ssh-keygen -f /sshvol/ssh_host_rsa_key -t rsa -b 4096 -N "" -C "root@${config.networking.hostName}"

    systemd-cryptenroll /dev/zvol/zroot/sshvol --unlock-key-file=/keyvol/sshvol_recovery.key --tpm2-device=auto --tpm2-pcrs=
  '';

  fstab = ''
    ${
      if cfg.encryption.tpm.remote.enable
      # nofail so it doesn't order before local-fs.target and therefore systemd-tmpfiles-setup
      then "/dev/mapper/keyvol /keyvol ext4 defaults,nofail,x-systemd.device-timeout=0,ro 0 2"
      else "/dev/mapper/keyvol /keyvol ext4 defaults 0 2"
    }
    ${
      lib.optionalString cfg.encryption.tpm.remote.enable
      "/dev/mapper/sshvol /sshvol ext4 defaults 0 2"
    }
    ${
      lib.optionalString cfg.encryption.tpm.remote.enable
      "/sshvol/var/lib/tailscale /var/lib/tailscale none bind,x-systemd.requires-mounts-for=/sshvol/var/lib/tailscale"
    }
  '';
in {
  options.lhf.boot.zfs = with lib; {
    enable = mkEnableOption "boot from ZFS";
    device = mkOption {
      type = types.str;
      description = "The device to boot from";
    };
    sizeESP = mkOption {
      type = types.str;
      description = "The size of the ESP partition";
      default = "512M";
    };
    encryption = {
      enable = mkEnableOption "encryption";
      tpm = {
        enable = mkEnableOption "TPM";
        remote = {
          enable = mkEnableOption "remote unlocking";
          tailscale = {
            enable = mkEnableOption "Tailscale in initrd";
            interfaceName = mkOption {
              type = types.str;
              description = "The network interface to use";
              default = "tun0";
            };
            port = mkOption {
              type = types.int;
              description = "The port to use";
              default = 0;
            };
          };
          authorizedKeys = mkOption {
            type = types.listOf types.str;
            description = "Authorized keys for remote unlocking";
          };
        };
      };
    };
  };

  imports = [
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      boot = {
        zfs = {
          devNodes = "/dev/disk/by-uuid"; # For some reason, /dev/vda was not under /dev/disk/by-id
          forceImportRoot = false;
        };
        initrd.systemd.enable = true;
        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot.enable = ! cfg.encryption.enable || ! cfg.encryption.tpm.enable; # disabled when lanzaboote is enabled
        };
      };

      disko.devices.disk.os = {
        inherit (cfg) device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = cfg.sizeESP;
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountOptions = ["umask=0077"];
                mountpoint = "/boot";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    }
    (lib.mkIf (! cfg.encryption.enable) {
      disko.devices.zpool.zroot = {
        mountpoint = "/";
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
        };
        postCreateHook = ''
          zfs list -t snapshot -H -o name | grep -E '^zroot@blank$' || zfs snapshot zroot@blank
        '';
      };
    })
    (lib.mkIf cfg.encryption.enable (lib.mkMerge [
      {
        boot.initrd = {
          availableKernelModules = ["ext4"];

          systemd = {
            enableTpm2 = cfg.encryption.tpm.enable;

            contents."/etc/fstab".text = fstab;

            services = {
              zfs-import-zroot.enable = false; # disable default zfs import

              zfs-import-zroot-bare = let
                devices = [(utils.escapeSystemdPath "/dev/disk/by-partlabel/disk-os-zfs.device")];
              in {
                enable = true;
                requiredBy = ["zroot-load-key.service"];
                after = devices;
                bindsTo = devices;
                unitConfig.DefaultDependencies = false;
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = "${config.boot.zfs.package}/bin/zpool import -f -N zroot";
                  RemainAfterExit = true;
                };
              };

              zroot-load-key = {
                enable = true;
                wantedBy = ["sysroot.mount"];
                before = ["sysroot.mount"];
                unitConfig = {
                  RequiresMountsFor = ["/keyvol"];
                  DefaultDependencies = false;
                };
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = "${config.boot.zfs.package}/bin/zfs load-key zroot/crypt";
                  RemainAfterExit = true;
                };
              };
            };
          };

          luks.devices.keyvol.device = "/dev/zvol/zroot/keyvol";
        };

        fileSystems."/keyvol".device = "/dev/mapper/keyvol";

        disko.devices.zpool.zroot = {
          rootFsOptions = {
            mountpoint = "none";
            compression = "zstd";
            "com.sun:auto-snapshot" = "false";
          };

          datasets = {
            keyvol = {
              type = "zfs_volume";
              size = "20M";
              content = {
                name = "keyvol";
                type = "luks";
                passwordFile = "/tmp/keyvol_recovery.key";
                content = {
                  type = "filesystem";
                  format = "ext4";
                };
                preCreateHook = generateKeys;
                postCreateHook = enrollKeys;
              };
            };
            crypt = {
              type = "zfs_fs";
              options = {
                mountpoint = "none";
                encryption = "aes-256-gcm";
                keyformat = "hex";
                keylocation = "file:///tmp/zfs.key";
              };
              preCreateHook = generateKeys;
              postCreateHook = ''
                zfs set keylocation="file:///keyvol/zfs.key" "zroot/$name"
              '';
            };
            "crypt/root" = {
              type = "zfs_fs";
              mountpoint = "/";
              postCreateHook = ''
                zfs list -t snapshot -H -o name | grep -E '^zroot/crypt/root@blank$' || zfs snapshot zroot/crypt/root@blank
              '';
            };
          };
        };
      }
      (lib.mkIf cfg.encryption.tpm.enable {
        boot = {
          initrd.luks.devices.keyvol.crypttabExtraOpts = ["tpm2-device=auto"];

          lanzaboote = {
            enable = true;
            pkiBundle = "/keyvol/secureboot";
          };
        };

        system.activationScripts.keyvol = ''
          if [ ! -d /keyvol ]; then
            mkdir -p /keyvol
            mount /dev/mapper/keyvol /keyvol
          fi
        '';

        environment.systemPackages = [sbctl pkgs.lhf.tpm-lockup];
      })
      (lib.mkIf (cfg.encryption.tpm.enable && cfg.encryption.tpm.remote.enable) (lib.mkMerge [
        {
          boot.initrd = {
            availableKernelModules = ["igb"];

            systemd = {
              inherit (config.systemd) network;

              contents."/etc/tmpfiles.d/50-ssh-host-keys.conf".text = ''
                C /etc/ssh/ssh_host_ed25519_key 0600 - - - /sshvol/ssh_host_ed25519_key
                C /etc/ssh/ssh_host_rsa_key 0600 - - - /sshvol/ssh_host_rsa_key
              '';

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
              inherit (cfg.encryption.tpm.remote) authorizedKeys;
              enable = true;
              ignoreEmptyHostKeys = true;
            };
          };

          fileSystems."/sshvol".device = "/dev/mapper/sshvol";
          systemd.tmpfiles.rules = [
            "C /etc/ssh/ssh_host_ed25519_key 0600 - - - /sshvol/ssh_host_ed25519_key"
            "C /etc/ssh/ssh_host_ed25519_key.pub 0644 - - - /sshvol/ssh_host_ed25519_key.pub"
            "C /etc/ssh/ssh_host_rsa_key 0600 - - - /sshvol/ssh_host_rsa_key"
            "C /etc/ssh/ssh_host_rsa_key.pub 0644 - - - /sshvol/ssh_host_rsa_key.pub"
          ];

          disko.devices.zpool.zroot.datasets.sshvol = {
            type = "zfs_volume";
            size = "20M";
            content = {
              name = "sshvol";
              type = "luks";
              passwordFile = "/tmp/sshvol_recovery.key";
              content = {
                type = "filesystem";
                format = "ext4";
              };
              preCreateHook = generateKeys;
              postCreateHook = generateHostKeys;
            };
          };
        }
        (lib.mkIf cfg.encryption.tpm.remote.tailscale.enable {
          boot.initrd = {
            availableKernelModules = ["tun" "nft_chain_nat"];

            systemd = {
              initrdBin = with pkgs; [iptables iproute2 iputils tailscale];
              packages = with pkgs; [tailscale];

              additionalUpstreamUnits = ["systemd-resolved.service"];
              users.systemd-resolve = {};
              groups.systemd-resolve = {};
              storePaths = ["${config.boot.initrd.systemd.package}/lib/systemd/systemd-resolved"];

              contents = {
                "/etc/systemd/resolved.conf" = {inherit (config.environment.etc."systemd/resolved.conf") source;};
                "/etc/hostname" = {inherit (config.environment.etc.hostname) source;};
                "/etc/tmpfiles.d/50-tailscale.conf".text = ''
                  L /var/run - - - - /run
                '';
              };

              network.networks."50-tailscale" = {
                matchConfig = {
                  Name = cfg.interfaceName;
                };
                linkConfig = {
                  Unmanaged = true;
                  ActivationPolicy = "manual";
                };
              };

              services = {
                systemd-resolved = {
                  wantedBy = ["initrd.target"];
                  serviceConfig.ExecStartPre = "-+/bin/ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf";
                };
                tailscaled = {
                  wantedBy = ["initrd.target"];
                  serviceConfig.Environment = [
                    "PORT=${toString cfg.encryption.tpm.remote.tailscale.port}"
                    ''"FLAGS=--tun ${lib.escapeShellArg cfg.encryption.tpm.remote.tailscale.interfaceName}"''
                  ];
                };
              };
            };
          };

          fileSystems."/var/lib/tailscale" = {
            depends = ["/sshvol"];
            device = "/sshvol/var/lib/tailscale";
            fsType = "none";
            options = ["bind"];
          };

          services.tailscale.enable = true;
        })
      ]))
    ]))
  ]);
}
