{
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  persist.local.directories = [
    "/var/lib/tailscale"
  ];
}
