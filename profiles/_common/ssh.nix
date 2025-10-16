{
  lib,
  publicKeys,
  config,
  ...
}: {
  services.openssh = {
    enable = true;
    hostKeys = []; # disables host key generation
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      HostKey = "/local/etc/ssh/ssh_host_ed25519_key"; # SSH key is placed by deploy-anywhere in /local/etc/ssh
    };
    authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
  };

  systemd.services = {
    sshd-keygen.enable = false;
    sshd.unitConfig.RequiresMountsFor = ["/local"];
  };

  user.openssh.authorizedKeys.keys = lib.mapAttrsToList (host: key: "${key} ${config.user.name}@${host}") publicKeys.user;
}
