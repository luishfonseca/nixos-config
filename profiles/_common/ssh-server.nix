{lib, ...}: {
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
    authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
  };
}
