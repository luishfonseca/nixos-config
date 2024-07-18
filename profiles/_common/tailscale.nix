{
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  lhf.dnsResolver.magicDNS = {
    enable = true;
    internalDomain = "in.lhf.pt";
    tailnet = "tail9db2a.ts.net";
  };

  persist.local.directories = [
    "/var/lib/tailscale"
  ];
}
