{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "arcturus";
  networking.firewall.allowPing = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  user.hashedPassword = "$6$fVkVAZBekeB.32U2$Pv6rLCSpeS/CPqXbkRXVolbzeRLlxDUEZ4IsGE.Q1jQ526J5nKT9fVReDu3dyg/An4Qn7zE83vJoKvQIn0EWV/";
  users.mutableUsers = false;

  lhf.services.ssh = {
    enable = true;
    host.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsXRuadobcfF3TxyIFUuxv1VPuHUyrl66ntNMolEORz";
    user.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM4vB3kJSlb/Ud7YbeEHQOca2gxQmmSL5kzkmx9uqs7j";
    allowSSHAgentAuth = true;
    manageKnownHosts.enable = true;
    manageSSHAuthKeys = {
      enable = true;
      extraKeys."luis@vega" = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBI51YbPjEZ/NGZ+ibWmyencNqZ1YYX111SIuPUzidGEMaT0oUYRPdLmRczgW3HPCoNpgV9Png0OFivDCJbPYhXo=";
    };
  };

  lhf.shell.fish = {
    enable = true;
    starship.enable = true;
    anyNixShell.enable = true;
    direnv.enable = true;
  };

  lhf.shell.dash = {
    enable = true;
    isSystemDefault = true;
  };

  boot.cleanTmpDir = true;

  security.acme.defaults.email = "luis@lhf.pt";
  security.acme.acceptTerms = true;

  mailserver = {
    enable = true;
    openFirewall = true;
    fqdn = "mail.lhf.pt";
    domains = [ "lhf.pt" ];
    localDnsResolver = false;

    loginAccounts = {
      "luis@lhf.pt" = {
        hashedPasswordFile = "/root/pwds/luis@lhf.pt.hash";
        aliases = [ "signups@lhf.pt" ];
      };
    };

    enableImap = false;
    enableImapSsl = true;
    enableSubmission = false;
    enableSubmissionSsl = true;
    enablePop3 = false;
    enablePop3Ssl = false;
    certificateScheme = 3;

    fullTextSearch = {
      enable = true;
      autoIndex = true;
      indexAttachments = true;
      enforced = "body";
    };
  };

  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    settings.dns = {
      bind_host = "127.0.0.1";
      port = 15353;
      upstream_dns = [ "tls://one.one.one.one" ];
      bootstrap_dns = [ "1.1.1.1" ];
      enable_dnssec = true;
    };
  };

  lhf.services.dns = {
    enable = true;
    forward = [ "127.0.0.1:15353" ];
    cache = 3600;
    tls = {
      enable = true;
      domain = "ns.lhf.pt";
      enableACME = true;
    };
    magicDNS = {
      enable = true;
      tailnet = "tail9db2a.ts.net";
      domain = config.networking.domain;
    };
  };

  services.tailscale.enable = true;

  networking.domain = "in.lhf.pt";
  networking.nameservers = [ "127.0.0.1" ];

  services.vaultwarden = {
    enable = true;
    config = {
      domain = "https://vault.lhf.pt";
      signupsAllowed = false;
      rocketPort = 8200;
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."vault.lhf.pt" = {
      forceSSL = true;
      enableACME = true;
      locations."/".proxyPass = "http://localhost:8200";
    };
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    allowedTCPPorts = [ 80 443 ];
    checkReversePath = "loose";
  };

  system.stateVersion = "21.05";
}
