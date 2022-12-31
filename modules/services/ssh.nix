{ config, options, lib, pkgs, nixosConfigurations, ... }:

with lib;
let cfg = config.lhf.services.ssh; in
{
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

    manageKnownHosts = mkEnableOption "known_hosts management" // { default = true; };

    manageSSHLogin = mkEnableOption "SSH login management" // { default = true; };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [ pkgs.openssh ];
      services.openssh = {
        enable = true;
        passwordAuthentication = false;
        hostKeys = [{
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }];
      };
      lhf.services.ssh = let all = filterAttrs (_: v: v.config.lhf.services.ssh.enable) nixosConfigurations; in
        {
          allHosts = filterAttrs (_: v: v != null) (mapAttrs' (_: v: nameValuePair v.config.lhf.services.ssh.host.name v.config.lhf.services.ssh.host.key) all);
          allUsers = filterAttrs (_: v: v != null) (mapAttrs' (_: v: nameValuePair v.config.lhf.services.ssh.user.name v.config.lhf.services.ssh.user.key) all);
        };
    }
    (mkIf cfg.manageKnownHosts {
      programs.ssh.knownHosts = mapAttrs (_: v: { publicKey = v; }) cfg.allHosts;
    })
    (mkIf cfg.manageSSHLogin {
      user.openssh.authorizedKeys.keys = mapAttrsToList (n: v: "${v} ${n}") cfg.allUsers;
    })
  ]);
}
