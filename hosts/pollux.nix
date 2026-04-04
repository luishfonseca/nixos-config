{
  inputs,
  config,
  profiles,
  modulesPath,
  ...
}: {
  imports = with profiles; [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.network-unlock.nixosModules.default
    bundle.server
    exit-node
    storage-box
    services.https-redirect
    services.backup-server
    services.rmfakecloud
    services.opencloud
    services.ente
    services.picgo
    services.s3
  ];

  lhf.tailscale.splitDns = {
    enable = true;
    domain = "lhf.pt";
    bypass = ["mail"];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "luis@lhf.pt";
    certs = {
      "lhf.pt" = {
        extraDomainNames = ["*.lhf.pt"];
        group = "caddy";
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.cf-dns-api-token.path;
      };
    };
  };

  networkUnlock = rec {
    server = {
      enable = true;
      openFirewall = true;
      internal = "100.123.137.111";
      public = "178.104.72.93";
    };
    client = {
      enable = true;
      units = ["tailscaled.service"];
      self = {
        inherit (server) internal public;
      };
      peer = {
        internal = "100.105.35.24";
        public = "158.178.156.3";
      };
      luks = {
        crypt = "root_crypt";
        key = "/recovery/root.key";
      };
    };
  };

  lhf.boot.disk = {
    bios = true;
    devices = [
      {
        path = "/dev/sda";
        size = "100%";
      }
    ];
  };

  boot = {
    loader.grub.configurationLimit = 3;
    initrd.systemd.network = {
      enable = true;
      networks."99-dhcp" = {
        matchConfig.Type = "ether";
        networkConfig.DHCP = "yes";
      };
    };
  };

  networking.useNetworkd = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";
}
