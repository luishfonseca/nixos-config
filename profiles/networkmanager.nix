{
  config,
  pkgs,
  ...
}: {
  networking.networkmanager = {
    enable = true;
    dns = "none";
    unmanaged = [
      "type:ethernet" # Let systemd-networkd handle ethernet interfaces
      config.services.tailscale.interfaceName
    ];
    wifi.powersave = true;
    plugins = with pkgs; [networkmanager-openconnect];
  };

  persist.system.directories = ["/etc/NetworkManager/system-connections"];

  user.extraGroups = ["networkmanager"];
}
