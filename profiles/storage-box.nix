{
  config,
  pkgs,
  ...
}: {
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
      "gid=100"
      "credentials=${config.sops.secrets.storage-box-credentials.path}"
    ];
  };
}
