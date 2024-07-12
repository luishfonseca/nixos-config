{
  lib,
  config,
  ...
}: {
  lhf.boot.zfs = {
    enable = true;
    encryption = {
      enable = lib.mkDefault true;
      tpm = {
        enable = true;
        remote = {
          enable = true;
          tailscale.enable = true;
          authorizedKeys = config.user.openssh.authorizedKeys.keys;
        };
      };
    };
  };
}
