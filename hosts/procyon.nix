{
  profiles,
  pkgs,
  ...
}: {
  imports = with profiles; [
    bundle.graphical
    bundle.dev
    autologin

    games
    discord

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

  hm.wayland.windowManager.hyprland.settings = {
    xwayland.force_zero_scaling = true;
  };

  boot = {
    consoleLogLevel = 3;

    # keyboard dead after suspend fix:
    # https://gitlab.com/tuxedocomputers/development/packages/linux/-/commit/ac7f9947f4289a476a21eb67e07cdb9669258567
    kernelParams = ["i8042.nomux=1" "i8042.reset=1" "i8042.noloop=1" "i8042.nopnp=1"];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
