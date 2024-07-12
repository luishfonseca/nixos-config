{config, ...}: {
  lhf.boot.zfs = {
    enable = true;
    tpmUnlocking = true;
    remoteUnlocking = {
      enable = true;
      tailscale.enable = true;
      authorizedKeys = config.user.openssh.authorizedKeys.keys;
    };
  };
}
