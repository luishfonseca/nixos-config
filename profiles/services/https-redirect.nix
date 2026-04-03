{
  services.caddy = {
    enable = true;
    virtualHosts.":80".extraConfig = ''
      redir https://{host}{uri} permanent
    '';
  };

  networking.firewall.allowedTCPPorts = [80];
}
