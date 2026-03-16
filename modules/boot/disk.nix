{
  inputs,
  config,
  utils,
  lib,
  pkgs,
  ...
}: let
  cfg = config.lhf.boot.disk;
in {
  options.lhf.boot.disk = with lib; {
    encrypt = (mkEnableOption "LUKS disk encryption") // {default = true;};
    bios = mkEnableOption "legacy BIOS boot (GPT + GRUB)";
    mirror = mkEnableOption "mirrored boot disk";
    hibernate = mkEnableOption "enable swap for hibernation";
    tpm = mkEnableOption "unlocking disk with TPM";
    size = {
      boot = mkOption {
        type = types.str;
        description = "Size of the boot partition";
        default = "512M";
      };
      root = mkOption {
        type = types.str;
        description = "Size of the tmpfs root";
        default = "16G";
      };
    };
    devices = mkOption {
      type = types.listOf (types.submodule {
        options = {
          id = mkOption {
            type = types.str;
            description = "ID of the disk";
          };
          size = mkOption {
            type = types.str;
            description = "Usable size";
          };
        };
      });
    };
  };

  imports = [
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  config = let
    sbctl = pkgs.lhf.sbctl.override {
      path = "/keys/sbctl";
    };

    boot = {
      type = "filesystem";
      mountpoint = "/boot";
      format = "vfat";
      mountOptions = ["umask=0077" "nofail"];
    };

    root_content =
      if cfg.encrypt
      then root_crypt
      else {
        type = "lvm_pv";
        vg = "root_pool";
      };

    root_crypt = {
      type = "luks";
      name = "root_crypt";
      passwordFile = "/keys/root.key";
      settings.allowDiscards = true;
      extraFormatArgs = ["--pbkdf argon2id"];
      content = {
        type = "lvm_pv";
        vg = "root_pool";
      };

      preCreateHook = ''
        mkdir -p /keys
        od -Anone -x -N 32 /dev/random | tr -d [:blank:] | tr -d '\n' > /keys/root.key
        chmod 600 /keys/root.key
      '';

      postCreateHook = ''
        systemd-cryptenroll "$(cryptsetup status root_crypt | awk '/device:/{print $2}')" --unlock-key-file=/keys/root.key ${
          if cfg.tpm
          then "--tpm2-device=auto --tpm2-pcrs="
          else "--password"
        }

        ${lib.optionalString cfg.tpm ''
          mkdir -p /recovery/sbctl
          ${sbctl}/bin/sbctl create-keys
          chmod -R 700 /recovery/sbctl

          if [ $(${sbctl}/bin/sbctl status --json | ${pkgs.jq}/bin/jq .setup_mode) = true ]; then
            ${sbctl}/bin/sbctl enroll-keys -m
          else
            printf '\e[1;31m%s\n%s\n\e[0m' \
              "WARNING: Secure Boot Setup Mode is not enabled!" \
              "You will need to enroll the keys manually."
          fi

          printf '\e[1;36m%s\n%s\n%s\n%s\n\e[0m' \
            "For TPM unlocking to be secure, ensure the following:" \
            "  - The BIOS has a password set" \
            "  - Secure Boot is enabled" \
            "  - Disks are bound to PCR7 (run \`tpm-lockup\` after first boot)"
        ''}

        printf '\e[1;33m%s\n\e[0m' \
          "Make sure to BACKUP /recovery after the first boot!"

        read -p "Press enter to continue..."
      '';
    };
  in
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.mirror -> (builtins.length cfg.devices > 1);
            message = "At least two disks are required for mirrored boot.";
          }
          {
            assertion = cfg.tpm -> cfg.encrypt;
            message = "TPM unlocking requires disk encryption to be enabled.";
          }
          {
            assertion = cfg.bios -> !cfg.tpm;
            message = "TPM unlocking requires UEFI and is incompatible with legacy BIOS boot.";
          }
        ];

        fileSystems."/nix".neededForBoot = true;

        disko.devices = {
          disk = lib.listToAttrs (lib.map (d:
            lib.nameValuePair d.id {
              type = "disk";
              device = "/dev/disk/by-id/${d.id}";
              content = {
                type = "gpt";
                partitions =
                  lib.optionalAttrs cfg.bios {
                    bios_boot = {
                      size = "1M";
                      type = "EF02";
                    };
                  }
                  // {
                    boot = {
                      size = cfg.size.boot;
                      type =
                        if cfg.bios
                        then "8300"
                        else "EF00";
                      content =
                        if cfg.mirror
                        then {
                          type = "mdraid";
                          name = "boot_mirror";
                        }
                        else boot;
                    };
                    root = {
                      inherit (d) size;
                      type = "8E00";
                      content =
                        if cfg.mirror
                        then {
                          type = "mdraid";
                          name = "root_mirror";
                        }
                        else root_content;
                    };
                  };
              };
            })
          cfg.devices);

          # TODO: Could be interesting making this zram with zram-generator
          nodev."/" = {
            fsType = "tmpfs";
            mountOptions = ["size=${cfg.size.root}" "mode=755"];
          };

          lvm_vg = {
            root_pool = {
              type = "lvm_vg";
              lvs =
                {
                  nix = {
                    size = "100%";
                    content = {
                      type = "filesystem";
                      format = "ext4";
                      mountOptions = ["noatime"];
                      mountpoint = "/nix";
                    };
                  };
                }
                // lib.optionalAttrs cfg.encrypt {
                  recovery = {
                    size = "64M";
                    content = {
                      type = "filesystem";
                      format = "ext4";
                      mountpoint = "/recovery";

                      # Move keys into the encrypted volume, and bind mount it back to /keys
                      # This way all previous keys are stored and more keys can be added
                      postMountHook = ''
                        mount -o remount,rw /mnt/recovery
                        for f in $(ls /keys); do
                          mv "/keys/$f" /mnt/recovery
                        done
                        mount --bind /mnt/recovery /keys
                      '';
                      preUnmountHook = ''
                        umount /keys
                      '';
                    };
                  };
                };
            };
          };
        };

        boot = {
          initrd.systemd = {
            enable = true;
            emergencyAccess = false; # See runbook on how to unlock if needed
          };
          loader = lib.mkIf (!cfg.bios) {
            systemd-boot.enable = !cfg.tpm;
            efi.canTouchEfiVariables = !cfg.mirror; # efibootmgr doesn't understand mirrored ESP
          };
        };

        systemd.enableEmergencyMode = true;
      }
      (lib.mkIf cfg.mirror {
        disko.devices.mdadm = {
          boot_mirror = {
            type = "mdadm";
            level = 1;
            metadata = "1.0"; # needed for bootable raid arrays, puts the metadata at the end of the partition
            content = boot;
          };

          root_mirror = {
            type = "mdadm";
            level = 1;
            content = root_content;
          };
        };

        boot.initrd.systemd.services = {
          # Hold off on assembling root-mirror until either all disks become available or timeout
          wait-boot-disks = let
            devices = lib.map (d: utils.escapeSystemdPath "/dev/disk/by-id/${d.id}.device") cfg.devices;
          in {
            wants = devices;
            after = devices;
            unitConfig = {
              DefaultDependencies = false;
              JobTimeoutSec = "10s"; # wait up to 10 seconds for disks to appear
            };
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "/bin/true";
              RemainAfterExit = true;
            };
          };

          assemble-root-mirror = let
            target =
              if cfg.encrypt
              then "systemd-cryptsetup@root_crypt.service"
              else "initrd-root-device.target";
          in {
            requiredBy = [target];
            before = [target];
            wants = ["wait-boot-disks.service"];
            after = ["wait-boot-disks.service"];
            unitConfig.DefaultDependencies = false;
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;

              ExecStart = "${pkgs.mdadm}/bin/mdadm --assemble /dev/md/root_mirror --name=root_mirror --run";
            };
          };
        };

        systemd.services.assemble-boot-mirror = {
          wantedBy = ["boot.mount"];
          before = ["boot.mount"];
          unitConfig.DefaultDependencies = false;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;

            # Resync boot_mirror in case firmware wrote to one of the disks
            ExecStart = "${pkgs.mdadm}/bin/mdadm --assemble /dev/md/boot_mirror --name=boot_mirror --homehost=any --run --update=resync";
          };
        };

        boot.swraid.mdadmConf = ''
          AUTO -all
          PROGRAM ${pkgs.coreutils}/bin/true
        ''; # Disable auto assembly
      })
      (lib.mkIf cfg.bios {
        boot.loader.grub = {
          enable = true;
          efiSupport = false;
          # devices is auto-set by disko from the EF02 partition
        };
      })
      (lib.mkIf cfg.tpm {
        boot = {
          initrd = {
            systemd.tpm2.enable = true;
            luks.devices.root_crypt.crypttabExtraOpts = [
              "tpm2-device=auto"

              # See Elvish's comment in https://discourse.nixos.org/t/a-modern-and-secure-desktop-setup/41154/17
              # This can only be enabled when remote is disabled, since that setup requires another disk to be auto-unlocked
              "tpm2-measure-pcr=yes"
            ];
          };

          lanzaboote = {
            enable = true;
            pkiBundle = "/recovery/sbctl"; # location of the sbctl keys on booted system
          };
        };

        environment.systemPackages = with pkgs; [
          (lhf.sbctl.override {path = "/recovery/sbctl";})
          lhf.tpm-lockup
        ];
      })
      (lib.mkIf cfg.hibernate {
        disko.devices.lvm_vg.root_pool.lvs.swap = {
          # Double the root size for swap to allow hibernation
          size = (sz: builtins.concatStringsSep "" [(builtins.toJSON ((lib.strings.toInt (builtins.elemAt sz 0)) * 2)) (builtins.elemAt sz 1)]) (builtins.match "([0-9]+)(.+)" cfg.size.root);
          content = {
            type = "swap";
            discardPolicy = "both";
            resumeDevice = true;
          };
        };
      })
    ];
}
