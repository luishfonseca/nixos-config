{config, ...}: {
  lhf.boot.zfs = {
    enable = true;
    tpmUnlocking = true;
    impermanence = {
      enable = true;
      home = true;
    };
    remoteUnlocking = {
      enable = true;
      tailscale.enable = true;
      authorizedKeys = config.user.openssh.authorizedKeys.keys;
    };
  };
}
