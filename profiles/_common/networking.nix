{config, ...}: {
  assertions = [
    {
      assertion = config.networking.interfaces == {};
      message = "Use systemd.network.networks for declarative network configuration, networking.interfaces must be empty.";
    }
  ];

  systemd.network = {
    enable = true;
    networks."99-ethernet-dhcp-fallback" = {
      matchConfig.Type = "ether";
      networkConfig = {
        IPv6AcceptRA = "yes";
        DHCP = "yes";
      };
    };
  };

  programs.captive-browser = {
    enable = true;
    bindInterface = false;
  };

  networking.networkmanager = {
    enable = true;
    dns = "none";
    unmanaged = [
      "type:ethernet" # Let systemd-networkd handle ethernet interfaces
      config.services.tailscale.interfaceName
    ];
    wifi.powersave = true;
  };

  user.extraGroups = ["networkmanager"];

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  lhf.dnsResolver = {
    enable = true;
    upstream = {
      name = "one.one.one.one";
      ip = "1.1.1.1";
    };
    magicDNS = {
      enable = true;
      internalDomain = "in.lhf.pt";
      tailnet = "tail9db2a.ts.net";
    };
  };
}
