{
  systemd.network.enable = true;

  networking = {
    # useDHCP = false;
    # dhcpcd.enable = false;
    useNetworkd = true;
    # networkmanager = {
    #   enable = true;
    #   dns = "none";
    #   wifi.powersave = true;
    # };
  };

  # user.extraGroups = ["networkmanager"];

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
