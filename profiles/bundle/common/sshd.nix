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
      HostKey = config.sops.secrets.ssh_host_ed25519.path;
    };
    authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
  };

  sops.secrets.ssh_host_ed25519.restartUnits = ["sshd.service"];

  user.openssh.authorizedKeys.keys = lib.mapAttrsToList (host: key: "${key} ${config.user.name}@${host}") publicKeys.user;

  systemd = {
    user.services.ssh-agent.serviceConfig.Restart = lib.mkForce "always";
    services = {
      sshd-keygen.enable = false;
      sshd = {
        wants = ["sops-install-secrets.service"];
        after = ["sops-install-secrets.service"];
      };
    };
  };
}
