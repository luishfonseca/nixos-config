{
  inputs,
  config,
  pkgs,
  lib,
  utils,
  ...
}: let
  cfg = config.lhf.zfs.fde;
in {
  options.lhf.zfs.fde = with lib; {
    enable = mkEnableOption "full disk encryption";
    tpm.enable = mkEnableOption "TPM";
  };

  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  config =
    lib.mkIf (
      cfg.enable
      && config.lhf.zfs.enable
    ) (lib.mkMerge [
      {
        disko.devices.zpool.zroot = {
          datasets = {
            root = {
              options = {
                encryption = "aes-256-gcm";
                keyformat = "hex";
                keylocation = "file:///keys/root.key";
              };
              preCreateHook = lib.lhf.genKey "root.key";
            };
            key_vol = {
              type = "zfs_volume";
              size = "64M";
              content = {
                name = "key_crypt";
                type = "luks";
                passwordFile = "/keys/key_vol.key";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/local/keys";
                  mountOptions = ["ro" "x-systemd.requires-mounts-for=/local"];

                  # Move keys into the encrypted volume, and bind mount it back to /keys
                  # This way all previous keys are stored and more keys can be added
                  postMountHook = ''
                    mount -o remount,rw /mnt/local/keys
                    for f in $(ls /keys); do
                      mv "/keys/$f" /mnt/local/keys
                    done
                    mount --bind /mnt/local/keys /keys
                  '';
                  preUnmountHook = ''
                    umount /keys
                  '';
                };

                preCreateHook = lib.lhf.genKey "key_vol.key";

                # Enroll the key_vol LUKS into the TPM or ask for password
                # When the TPM is enabled, no PCRs are specified and the user must use tpm-lockup after reboot
                postCreateHook = ''
                  ${lib.optionalString cfg.tpm.enable ''
                    printf '\e[1;36m%s\n%s\n%s\n%s\n\e[0m' \
                      "For TPM unlocking to be secure, ensure the following:" \
                      "  - The BIOS has a password set" \
                      "  - Secure Boot is enabled" \
                      "  - Disks are bound to PCR7 (run \`tpm-lockup\` after first boot)"
                  ''}

                  printf '\e[1;33m%s\n\e[0m' \
                    "Make sure to BACKUP /local/keys/root.key after the first boot!"

                  read -p "Press enter to continue..."

                  systemd-cryptenroll /dev/zvol/zroot/key_vol --unlock-key-file=/keys/key_vol.key ${
                    if cfg.tpm.enable
                    then "--tpm2-device=auto --tpm2-pcrs="
                    else "--password"
                  }
                '';
              };
            };
          };
        };

        boot = {
          loader.systemd-boot.enable = true;

          initrd = {
            availableKernelModules = ["ext4"];

            luks.devices.key_crypt = {
              device = "/dev/zvol/zroot/key_vol";
              crypttabExtraOpts = ["nofail"];
            };

            systemd = {
              contents."/etc/fstab".text = ''
                /dev/mapper/key_crypt /keys ext4 nofail,x-systemd.device-timeout=0,ro 0 2
              '';

              services = {
                # Disable the default zfs import service
                zfs-import-zroot.enable = false;

                # Hold off on importing zroot until either all disks become available or timeout
                zfs-import-wait = let
                  devices = lib.map (d: utils.escapeSystemdPath "/dev/disk/by-partlabel/disk-${d.label}-zfs.device") config.lhf.zfs.disks;
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

                # Import zroot without mounting filesystems
                zfs-import-zroot-bare = {
                  wants = ["zfs-import-wait.service"];
                  after = ["zfs-import-wait.service"];
                  requiredBy = ["systemd-cryptsetup@key_crypt.service"];
                  before = ["systemd-cryptsetup@key_crypt.service"];
                  unitConfig.DefaultDependencies = false;
                  serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${config.boot.zfs.package}/bin/zpool import -N zroot";
                    RemainAfterExit = true;
                  };
                };

                # Once the key volume is unlocked and mounted, load the encryption key for zroot/root
                zroot-load-key = {
                  requires = ["zfs-import-zroot-bare.service"];
                  after = ["zfs-import-zroot-bare.service"];
                  requiredBy = ["sysroot.mount"];
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
          };
        };
      }
      (
        lib.mkIf cfg.tpm.enable {
          # Create and enroll secure boot keys
          disko.devices.zpool.zroot.datasets.root.postCreateHook = lib.mkBefore (let
            sbctl = pkgs.lhf.sbctl.override {
              path = "/keys/sbctl";
            };
          in ''
            mkdir -p /keys/sbctl
            ${sbctl}/bin/sbctl create-keys

            if [ $(${sbctl}/bin/sbctl status --json | ${pkgs.jq}/bin/jq .setup_mode) = true ]; then
              ${sbctl}/bin/sbctl enroll-keys -m
            else
              printf '\e[1;31m%s\n%s\n\e[0m' \
                "WARNING: Secure Boot Setup Mode is not enabled!" \
                "You will need to enroll the keys manually."
            fi
          '');

          boot = {
            loader.systemd-boot.enable = lib.mkForce false;

            initrd = {
              luks.devices.key_crypt.crypttabExtraOpts =
                ["tpm2-device=auto"]
                ++ [
                  # See Elvish's comment in https://discourse.nixos.org/t/a-modern-and-secure-desktop-setup/41154/17
                  # This can only be enabled when remote is disabled, since that setup requires another disk to be auto-unlocked
                  (lib.optionalString (! cfg.tpm.remote.enable) "tpm2-measure-pcr=yes")
                ]; #
              systemd.tpm2.enable = true;
            };

            lanzaboote = {
              enable = true;
              pkiBundle = "/local/keys/sbctl"; # location of the sbctl keys on booted system
            };
          };

          environment.systemPackages = with pkgs; [lhf.sbctl lhf.tpm-lockup];
        }
      )
    ]);
}
