{profiles, ...}: {
  imports = with profiles; [networkmanager];

  programs.captive-browser = {
    enable = true;
    bindInterface = false;
  };

  systemd.network.wait-online.enable = false;

  services.tzupdate.enable = true;
}
