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
    "/var/log"
    "/var/db/sudo/lectured"
  ];

  persist.user.local.files = [
    ".bash_history"
  ];
}
