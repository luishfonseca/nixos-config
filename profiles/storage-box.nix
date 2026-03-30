{
  config,
  pkgs,
  ...
}: {
  users.groups.box.gid = 500;
  users.users.${config.user.name}.extraGroups = ["box"];

  environment.systemPackages = [pkgs.cifs-utils];
  fileSystems."/mnt/box" = {
    device = "//u562378.your-storagebox.de/backup";
    fsType = "cifs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "uid=1000"
      "gid=${toString config.users.groups.box.gid}"
      "dir_mode=0770"
      "file_mode=0660"
      "credentials=${config.sops.secrets.storage-box-credentials.path}"
    ];
  };

  programs.fuse.userAllowOther = true;

  systemd.services.vault = let
    passfile = config.sops.secrets.gocryptfs-password.path;
    cipher = "/mnt/box/vault";
    plain = "/mnt/vault";
  in {
    description = "gocryptfs vault on storage box";
    requires = ["mnt-box.automount"];
    after = ["mnt-box.automount"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.gocryptfs pkgs.util-linux];

    script = ''
      mkdir -p ${cipher} ${plain}
      if [ ! -f ${cipher}/gocryptfs.conf ]; then
        gocryptfs -init -passfile ${passfile} ${cipher}
      fi
      exec gocryptfs -fg -allow_other -passfile ${passfile} ${cipher} ${plain}
    '';

    serviceConfig = {
      Type = "simple";
      ExecStop = "${pkgs.util-linux}/bin/fusermount -u ${plain}";
      Restart = "on-failure";
    };
  };
}
