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
      dhcpV4Config.UseDNS = false;
      dhcpV6Config.UseDNS = false;
      ipv6AcceptRAConfig.UseDNS = false;
    };
  };

  networking.nameservers = ["1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one"];

  services.resolved = {
    enable = true;
    dnssec = "true";
    dnsovertls = "true";
  };
}
