{
  lib,
  config,
  ...
}: {
  lhf.fsRoot = {
    enable = true;
    tmpfs = true;
  };

  persist = {
    local = {
      files =
        [
          "/etc/machine-id"
        ]
        ++ lib.concatMap (key: [key.path (key.path + ".pub")]) config.services.openssh.hostKeys;

      directories = [
        {
          # needed for large builds to work
          directory = "/tmp";
          mode = "1777";
        }

        "/var/log"
        "/var/db/sudo/lectured"
        "/var/lib/nixos"
      ];
    };

    user.local.files = [
      ".bash_history"
    ];
  };

  boot.tmp.cleanOnBoot = true;
}
