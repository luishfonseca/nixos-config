{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.ssh = {
    startAgent = true;
    agentTimeout = "1h";
    extraConfig = ''
      AddKeysToAgent yes
    '';
  };

  age.secrets.id_ed25519 = {
    path = "/home/${config.user.name}/.ssh/id_ed25519";
    owner = config.user.name;
    mode = "400";
    symlink = false;
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
