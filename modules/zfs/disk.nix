{
  inputs,
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  cfg = config.lhf.zfs;
in {
  options.lhf.zfs = with lib; {
    enable = mkEnableOption "ZFS root filesystem";
    disks = mkOption {
      type = types.listOf (types.submodule {
        options = {
          label = mkOption {
            type = types.str;
            description = "Label for the disk";
          };
          path = mkOption {
            type = types.str;
            description = "Path to the disk";
          };
          size = mkOption {
            type = types.str;
            description = "Usable size for ZFS";
          };
        };
      });
    };
    topology = mkOption {
      type = types.attrs;
      description = "ZFS topology";
    };
    boot = {
      disks = mkOption {
        type = types.listOf types.str;
        description = "Labels of the bootable disks";
        default = [(lib.head cfg.disks).label]; # TODO: test if single disk works
      };
      sizeESP = mkOption {
        type = types.str;
        description = "Size of the ESP partition";
        default = "512M";
      };
    };
  };

  imports = [
    inputs.disko.nixosModules.disko
  ];

  config = let
    mirrored-esp = lib.length cfg.boot.disks > 1;
  in
    lib.mkIf cfg.enable (lib.mkMerge [
      {
        assertions = let
          disks = lib.map (d: d.label) cfg.disks;
        in [
          {
            assertion = builtins.all (d: lib.elem d disks) cfg.boot.disks;
            message = ''
              All bootable disks (${toString cfg.boot.disks})
              must be in disks: ${toString disks}
            '';
          }
        ];

        disko.devices = {
          disk = lib.listToAttrs (lib.map (d:
            lib.nameValuePair d.label {
              type = "disk";
              device = d.path;
              content = {
                type = "gpt";
                partitions = {
                  ESP = lib.mkIf (lib.elem d.label cfg.boot.disks) {
                    size = cfg.boot.sizeESP;
                    type = "EF00";
                    content =
                      if mirrored-esp
                      then {
                        type = "mdraid";
                        name = "boot";
                      }
                      else {
                        type = "filesystem";
                        mountpoint = "/boot";
                        format = "vfat";
                        mountOptions = ["umask=0077"];
                      };
                  };
                  zfs = {
                    inherit (d) size;
                    content = {
                      type = "zfs";
                      pool = "zroot";
                    };
                  };
                };
              };
            })
          cfg.disks);

          zpool.zroot = {
            type = "zpool";
            mode.topology = lib.mkAliasDefinitions options.lhf.zfs.topology;

            rootFsOptions = {
              mountpoint = "none";
              compression = "on";
              "com.sun:auto-snapshot" = "false";
            };

            options.ashift = "12";

            datasets.root = {
              type = "zfs_fs";
              mountpoint = "/";
              postCreateHook = ''
                zfs list -t snapshot -H -o name | grep -E '^zroot/root@blank$' || zfs snapshot zroot/root@blank
              '';
            };
          };
        };

        boot = {
          zfs.forceImportRoot = false;
          initrd.systemd.enable = true;
          loader = {
            efi.canTouchEfiVariables = ! mirrored-esp; # efibootmgr doesn't understand mirrored ESP
            systemd-boot.configurationLimit = 2;
          };
        };
      }
      (lib.mkIf mirrored-esp {
        disko.devices.mdadm.boot = {
          type = "mdadm";
          level = 1;
          metadata = "1.0";
          content = {
            mountpoint = "/boot";
            type = "filesystem";
            format = "vfat";
            mountOptions = ["umask=0077" "noauto"]; # don't automount /boot
          };
        };

        boot.swraid = {
          enable = true;
          mdadmConf = ''
            AUTO -all
            PROGRAM ${pkgs.coreutils}/bin/true
          ''; # don't auto assemble /dev/md/boot
        };

        systemd.services."mount-boot" = {
          wantedBy = ["multi-user.target"];
          enable = true;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = [
              "${pkgs.mdadm}/bin/mdadm --assemble /dev/md/boot --run --name=boot --update=resync" # resync in case firmware wrote to one of the disks
              "${pkgs.mount}/bin/mount /dev/md/boot"
            ];
            RemainAfterExit = true;
          };
        };
      })
    ]);
}
