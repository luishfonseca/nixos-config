{
  lib,
  config,
  publicKeys,
  pkgs,
  ...
}: {
  programs.ssh = {
    startAgent = true;
    agentTimeout = "1h";
    extraConfig = ''
      AddKeysToAgent yes
    '';

    knownHosts =
      builtins.foldl' (x: y: x // y) {}
      (lib.mapAttrsToList (host: key: {${host}.publicKey = "${key} root@${host}";}) publicKeys.host);
  };

  sops.secrets.id_ed25519 = {
    path = "/home/${config.user.name}/.ssh/id_ed25519";
    owner = config.user.name;
  };

  systemd = {
    services.chown-ssh-dir = {
      description = "Ensure correct ownership of .ssh directory";
      wantedBy = ["sops-install-secrets.service"];
      after = ["sops-install-secrets.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.coreutils}/bin/chown ${config.user.name}:users /home/${config.user.name}/.ssh
        '';
        RemainAfterExit = true;
      };
    };
    user.services.ssh-agent.serviceConfig.Restart = lib.mkForce "always";
    services.lock-ssh-agent = {
      description = "Lock SSH Agent";
      wantedBy = ["suspend.target" "hibernate.target"];
      before = ["systemd-suspend.service" "systemd-hibernate.service" "systemd-suspend-then-hibernate.service"];
      serviceConfig = {
        ExecStart = "${pkgs.killall}/bin/killall ssh-agent";
        Type = "forking";
      };
    };
  };
}
