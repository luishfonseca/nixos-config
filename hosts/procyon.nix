{
  profiles,
  pkgs,
  ...
}: {
  imports = with profiles; [
    client
    autologin
    hardware.common-pc
    cpu-amd
  ];

  lhf.zfs = {
    enable = true;
    disks = [
      {
        path = "/dev/disk/by-id/nvme-Samsung_SSD_990_EVO_Plus_2TB_S7U7NU0Y641298E";
        label = "S7U7NU0Y641298E";
        size = "1860G";
      }
      {
        path = "/dev/disk/by-id/nvme-Samsung_SSD_990_EVO_Plus_2TB_S7U7NU0Y641450R";
        label = "S7U7NU0Y641450R";
        size = "1860G";
      }
    ];
    topology = {
      type = "topology";
      vdev = [
        {
          mode = "mirror";
          members = [
            "S7U7NU0Y641298E"
            "S7U7NU0Y641450R"
          ];
        }
      ];
    };
    boot.disks = [
      "S7U7NU0Y641298E"
      "S7U7NU0Y641450R"
    ];
    fde = {
      enable = true;
      tpm.enable = true;
    };
  };

  boot.consoleLogLevel = 3;

  networking.hostId = "22ab2bed";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
