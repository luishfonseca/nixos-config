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

  boot.tmp.cleanOnBoot = true;

  mailserver =
    let
      acmePath = config.security.acme.certs."arcturus.lhf.pt".directory;
    in
    rec {
      fqdn = "mail.lhf.pt";
      enable = true;
      openFirewall = true;
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

      certificateScheme = "manual";
      certificateFile = "${acmePath}/fullchain.pem";
      keyFile = "${acmePath}/key.pem";

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
    settings = {
      bind_port = 8201;
      users = [{
        name = "luis";
        password = "$2y$05$YcZ/LRq3nzw5QAT1U15v5ezPpDBk6ksukRfTgbl.JsYYA4Dlhdp6u";
      }];
      dns = {
        bind_host = "127.0.0.1";
        port = 15353;
        upstream_dns = [ "tls://one.one.one.one" ];
        bootstrap_dns = [ "1.1.1.1" ];
        enable_dnssec = true;
      };
      log = {
        max_size = 100;
        compress = true;
      };
    };
  };

  lhf.services.dns = {
    enable = true;
    forward = [ "127.0.0.1:15353" ];
    cache = 3600;
    tls = {
      enable = true;
      acmeHost = "arcturus.lhf.pt";
    };
    magicDNS = {
      enable = true;
      tailnet = "tail9db2a.ts.net";
      domain = config.networking.domain;
    };
  };

  services.tailscale.enable = true;

  networking.domain = "in.lhf.pt";

  networking.dhcpcd.extraConfig = "nohook resolv.conf";
  networking.nameservers = [ "127.0.0.1" ];

  services.vaultwarden = {
    enable = true;
    config = {
      domain = "https://vault.lhf.pt";
      signupsAllowed = false;
      rocketPort = 8200;
    };
  };

  lhf.services.reverseProxy = {
    enable = true;
    acmeHost = "arcturus.lhf.pt";
    host = "lhf.pt";
    sites = {
      "vault.lhf.pt"."/" = "http://localhost:8200";
      "ads.lhf.pt"."/" = "http://localhost:8201";
    };
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    allowedTCPPorts = [ 80 443 ];
    checkReversePath = "loose";
  };

  nix.gc.automatic = true;

  system.stateVersion = "21.05";
}
