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
}
