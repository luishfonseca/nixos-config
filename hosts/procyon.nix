{
  profiles,
  config,
  ...
}: {
  imports = with profiles; [
    bundle.graphical
    bundle.dev
    bundle.entertainment
    autologin

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

    monitor = [
      "desc:Dell Inc. DELL U2713HM 7JNY53BB272L, 1920x1080@60, auto-left, 1" # work monitor
      "eDP-1, 2560x1600@180, 0x0, 1.6"
    ];
  };

  boot = {
    consoleLogLevel = 3;

    extraModulePackages = with config.boot.kernelPackages; [
      yt6801 # ethernet driver
    ];

    # keyboard dead after suspend fix:
    # https://gitlab.com/tuxedocomputers/development/packages/linux/-/commit/ac7f9947f4289a476a21eb67e07cdb9669258567
    kernelParams = ["i8042.nomux=1" "i8042.reset=1" "i8042.noloop=1" "i8042.nopnp=1"];
  };

  hardware.tuxedo-drivers.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
