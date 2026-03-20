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

  networking.nameservers = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];

  services.resolved = {
    enable = true;
    domains = [ "~." ]; # always use systemd-resolved
    dnssec = "true";
    dnsovertls = "true";
  };
}
