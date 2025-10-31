{
  profiles,
  pkgs,
  ...
}: {
  imports = with profiles; [
    bundle.graphical
    bundle.dev
    autologin
    hardware.common-pc
    cpu-amd
  ];

  lhf.boot.disk = {
    mirror = true;
    hibernate = true;
    tpm = true;
    devices = [
      {
        id = "nvme-Samsung_SSD_990_EVO_Plus_2TB_S7U7NU0Y641298E";
        size = "1860G";
      }
      {
        id = "nvme-Samsung_SSD_990_EVO_Plus_2TB_S7U7NU0Y641450R";
        size = "1860G";
      }
    ];
  };

  persist = {
    system = {
      directories = [
        "/var/log"
        "/var/lib/"
        "/etc/NetworkManager/system-connections"
      ];
      files = [
        "/etc/machine-id"
      ];
    };
    home = {
      directories = [
        # Chromium
        ".config/chromium"
        ".cache/chromium"
        ".pki"

        # Gnome Keyring
        ".local/share/keyrings"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    chromium
  ];

  boot.consoleLogLevel = 3;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
