{
  config,
  options,
  lib,
  pkgs,
  nixosConfigurations,
  ...
}:
with lib; let
  cfg = config.lhf.services.ssh;
in {
  options.lhf.services.ssh = {
    enable = mkEnableOption "SSH Key Management";

    host = {
      name = mkOption {
        type = types.str;
        default = config.networking.hostName;
        description = "SSH host name";
      };
      key = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "SSH host key";
      };
    };

    allHosts = mkOption {
      type = types.attrsOf (types.nullOr types.str);
    };

    user = {
      name = mkOption {
        type = types.str;
        default = "${config.user.name}@${config.networking.hostName}";
        description = "SSH user name";
      };
      key = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "SSH user key";
      };
    };

    allUsers = mkOption {
      type = types.attrsOf (types.nullOr types.str);
    };

    allowSSHAgentAuth = mkEnableOption "SSH agent authentication";

    preferAskPassword = mkEnableOption "Prefer ASKPASS";

    manageKnownHosts = {
      enable = mkEnableOption "SSH hosts management";
      extraHosts = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Extra known_hosts";
      };
    };

    manageSSHAuthKeys = {
      enable = mkEnableOption "SSH authorized_keys management";
      extraKeys = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Extra authorized_keys";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [pkgs.openssh];

      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
        hostKeys = [
          {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];
      };

      programs.ssh = {
        startAgent = true;
        agentTimeout = "1h";
        extraConfig = ''
          AddKeysToAgent yes
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

      lhf.services.ssh = let
        all = filterAttrs (_: v: v.config.lhf.services.ssh.enable) nixosConfigurations;
      in {
        allHosts = filterAttrs (_: v: v != null) (mapAttrs' (_: v: nameValuePair v.config.lhf.services.ssh.host.name v.config.lhf.services.ssh.host.key) all);
        allUsers = filterAttrs (_: v: v != null) (mapAttrs' (_: v: nameValuePair v.config.lhf.services.ssh.user.name v.config.lhf.services.ssh.user.key) all);
      };
    }
    (mkIf cfg.manageKnownHosts.enable {
      programs.ssh.knownHosts = mapAttrs (_: v: {publicKey = v;}) (cfg.allHosts // cfg.manageKnownHosts.extraHosts);
      programs.ssh.extraConfig =
        concatMapStringsSep "\n"
        (host: ''
          Host ${host}
            User ${config.user.name}
            ${optionalString (config.networking.domain != null) "HostName ${host}.${config.networking.domain}"}
            ${optionalString cfg.allowSSHAgentAuth "ForwardAgent yes"}
        '')
        (attrNames cfg.allHosts);
    })
    (mkIf cfg.manageSSHAuthKeys.enable {
      user.openssh.authorizedKeys.keys = mapAttrsToList (n: v: "${v} ${n}") (cfg.allUsers // cfg.manageSSHAuthKeys.extraKeys);
    })
    (mkIf cfg.allowSSHAgentAuth {
      security = {
        sudo.enable = true;
        pam.sshAgentAuth.enable = true;
        pam.services.sudo.sshAgentAuth = true;
      };
    })
    (mkIf cfg.preferAskPassword {
      environment.variables.SSH_ASKPASS_REQUIRE = "prefer";
      systemd.user.services.ssh-agent.environment.SSH_ASKPASS_REQUIRE = "prefer";
    })
  ]);
}
