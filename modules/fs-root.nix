{
  inputs,
  config,
  options,
  pkgs,
  lib,
  ...
}: let
  cfg = config.lhf.fsRoot;
in {
  options = with lib; {
    lhf.fsRoot = {
      enable = mkEnableOption "encrypted root filesystem";
      device = {
        ssd = mkOption {
          type = types.bool;
          description = "Whether the device is an SSD";
          default = false;
        };
        path = mkOption {
          type = types.str;
          description = "Path to the device to boot from";
        };
      };
      sizeESP = mkOption {
        type = types.str;
        description = "The size of the ESP partition";
        default = "512M";
      };
      encryption = {
        enable = mkEnableOption "encryption";
        tpm = mkEnableOption "unlock with TPM";
      };
      tmpfs = mkEnableOption "root on tmpfs";
    };

    persist.data = mkOption {type = types.attrs;};
    persist.local = mkOption {type = types.attrs;};
    persist.user.data = mkOption {type = types.attrs;};
    persist.user.local = mkOption {type = types.attrs;};
  };

  imports = [
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.impermanence.nixosModules.impermanence
  ];

  config = let
    pkiBundle =
      if cfg.tmpfs
      then "/pst/data/etc/secureboot"
      else "/etc/secureboot";

    sbctl = pkgs.sbctl.override {
      databasePath = pkiBundle;
    };
  in
    lib.mkIf cfg.enable (lib.mkMerge [
      {
        boot = {
          loader = {
            efi.canTouchEfiVariables = true;
            systemd-boot.enable = ! cfg.encryption.tpm;
          };

          initrd.systemd.enable = true;
        };

        environment.extraInit = ''
          umask 0027
        '';

        disko.devices.disk.os = {
          type = "disk";
          device = cfg.device.path;
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
              root = {
                size = "100%";
                content = let
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountOptions = ["noatime"];
                    mountpoint =
                      if cfg.tmpfs
                      then "/pst"
                      else "/";

                    postCreateHook = lib.optionalString cfg.tmpfs ''
                      mkdir -p /tmp/pst

                      mount ${
                        if cfg.encryption.enable
                        then "/dev/mapper/crypt"
                        else "/dev/disk/by-partlabel/disk-os-root"
                      } /tmp/pst

                      mkdir -p /tmp/pst
                      mkdir -p /tmp/pst/data
                      mkdir -p /tmp/pst/local
                      mkdir -p /tmp/pst/local/nix

                      umount /tmp/pst
                    '';

                    postMountHook = lib.optionalString cfg.tmpfs ''
                      mkdir -p /mnt/nix
                      mount --bind /mnt/pst/local/nix /mnt/nix
                    '';
                  };
                in
                  if cfg.encryption.enable
                  then
                    ({
                        type = "luks";
                        name = "crypt";
                        settings.allowDiscards = true;

                        preCreateHook = ''
                          od -Anone -x -N 32 /dev/random | tr -d '[:blank:]' | tr -d '\n' > /tmp/fsroot_recovery.key
                          chmod 600 /tmp/fsroot_recovery.key
                        '';

                        postCreateHook = ''
                          mkdir -p /tmp/crypt
                          mount /dev/mapper/crypt /tmp/crypt
                          cp /tmp/fsroot_recovery.key /tmp/crypt${lib.optionalString cfg.tmpfs "/data"}

                          ${lib.optionalString cfg.encryption.tpm ''
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

                            read -p "Press enter to continue..."

                            systemd-cryptenroll /dev/disk/by-partlabel/disk-os-root --unlock-key-file /tmp/fsroot_recovery.key --tpm2-device=auto --tpm2-pcrs=

                            ${sbctl}/bin/sbctl create-keys
                            if [ $(${sbctl}/bin/sbctl status --json | ${pkgs.jq}/bin/jq .setup_mode) = true ]; then
                              ${sbctl}/bin/sbctl enroll-keys -m
                            fi

                            mkdir -p /tmp/crypt${lib.optionalString cfg.tmpfs "/data"}/etc/secureboot
                            mv ${pkiBundle} /tmp/crypt${lib.optionalString cfg.tmpfs "/data"}/etc
                          ''}

                          umount /tmp/crypt
                        '';

                        inherit content;
                      }
                      // (
                        if cfg.encryption.tpm
                        then {
                          passwordFile = "/tmp/fsroot_recovery.key";
                        }
                        else {
                          settings.crypttabExtraOpts = ["tpm2-device=auto"];
                          additionalKeyFiles = ["/tmp/fsroot_recovery.key"];
                        }
                      ))
                  else content;
              };
            };
          };
        };
      }
      (lib.mkIf (cfg.encryption.enable && cfg.encryption.tpm) {
        boot.lanzaboote = {
          enable = true;
          inherit pkiBundle;
        };

        environment.systemPackages = [
          pkgs.lhf.tpm-lockup
          sbctl
        ];
      })
      {
        environment.persistence."/pst/data" = lib.mkAliasDefinitions options.persist.data;
        persist.data = {
          enable = cfg.tmpfs;
          users.${config.user.name} = lib.mkAliasDefinitions options.persist.user.data;
        };

        environment.persistence."/pst/local" = lib.mkAliasDefinitions options.persist.local;
        persist.local = {
          enable = cfg.tmpfs;
          users.${config.user.name} = lib.mkAliasDefinitions options.persist.user.local;
        };
      }
      (lib.mkIf cfg.tmpfs {
        disko.devices.nodev."/" = {
          fsType = "tmpfs";
          mountOptions = ["mode=755"];
        };

        fileSystems = {
          "/pst".neededForBoot = true;
          "/nix" = {
            device = "/pst/local/nix";
            neededForBoot = true;
            fsType = "none";
            options = ["bind"];
          };
        };

        systemd.services."root-checksums" = {
          description = "Calculate SHA256 checksums for root filesystem files";
          wantedBy = ["multi-user.target"];
          serviceConfig = let
            root-checksums = pkgs.writeScript "root-checksums" ''
              #!${pkgs.runtimeShell}
              touch /pst/local/root-checksums.txt
              chmod 600 /pst/local/root-checksums.txt
              ${pkgs.findutils}/bin/find '/' -mount -path '/nix' -prune -o -type f |
                sed '/\/nix/d' |
                sort |
                ${pkgs.findutils}/bin/xargs ${pkgs.coreutils}/bin/sha256sum > /pst/local/root-checksums.txt
            '';
          in {
            Type = "oneshot";
            ExecStop = "${root-checksums}";
            RemainAfterExit = true;
          };
        };

        environment.systemPackages = [pkgs.lhf.root-diff];
      })
    ]);
}
