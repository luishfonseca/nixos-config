{config, ...}: {
  networking.networkmanager = {
    enable = true;
    dns = "none";
    unmanaged = [
      "type:ethernet" # Let systemd-networkd handle ethernet interfaces
      config.services.tailscale.interfaceName
    ];
    wifi.powersave = true;
  };

  persist.system.directories = ["/etc/NetworkManager/system-connections"];

  user.extraGroups = ["networkmanager"];
}
