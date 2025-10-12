{
  lib,
  publicKeys,
  config,
  ...
}: {
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
    authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
  };

  user.openssh.authorizedKeys.keys = lib.mapAttrsToList (host: key: "${key} ${config.user.name}@${host}") publicKeys.user;
}
