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

  systemd.tmpfiles.settings.prepare-home-ssh."/home/${config.user.name}/.ssh".d = {
    user = config.user.name;
    group = "users";
    mode = "0755";
  };

  persist.home.files = [".ssh/known_hosts"];

  systemd.services.lock-ssh-agent = {
    description = "Lock SSH Agent";
    wantedBy = ["suspend.target" "hibernate.target"];
    before = ["systemd-suspend.service" "systemd-hibernate.service" "systemd-suspend-then-hibernate.service"];
    serviceConfig = {
      ExecStart = "${pkgs.killall}/bin/killall ssh-agent";
      Type = "forking";
    };
  };
}
