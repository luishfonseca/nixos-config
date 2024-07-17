{
  lib,
  config,
  ...
}: {
  lhf.fsRoot = {
    enable = true;
    tmpfs = true;
  };

  persist.local.files =
    [
      "/etc/machine-id"
      "/var/lib/logrotate.status"
    ]
    ++ lib.concatMap (key: [key.path (key.path + ".pub")]) config.services.openssh.hostKeys;

  persist.local.directories = [
    {
      # needed for large builds to work
      directory = "/tmp";
      mode = "1777";
    }

    "/var/log"
    "/var/db/sudo/lectured"
  ];

  persist.user.local.files = [
    ".bash_history"
  ];

  boot.tmp.cleanOnBoot = true;
}
