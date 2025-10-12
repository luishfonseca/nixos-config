{
  config,
  pkgs,
  lib,
  publicKeys,
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

  age.secrets.id_ed25519 = {
    path = "/home/${config.user.name}/.ssh/id_ed25519";
    owner = config.user.name;
    symlink = false;
  };

  system.activationScripts.lhfCreateDirSSH = {
    # agenix creates the directory, owned by root. This fixes that.
    deps = ["agenix"];
    text = ''
      chown ${config.user.name} /home/${config.user.name}/.ssh
      chmod 700 /home/${config.user.name}/.ssh
    '';
  };

  systemd.user.services.ssh-agent.serviceConfig.Restart = lib.mkForce "always";
  systemd.services.lock-ssh-agent = {
    enable = true;
    description = "Lock SSH Agent";
    wantedBy = ["suspend.target" "hibernate.target"];
    before = ["systemd-suspend.service" "systemd-hibernate.service" "systemd-suspend-then-hibernate.service"];
    serviceConfig = {
      ExecStart = "${pkgs.killall}/bin/killall ssh-agent";
      Type = "forking";
    };
  };
}
