{
  inputs,
  profiles,
  modulesPath,
  ...
}: {
  imports = with profiles; [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.network-unlock.nixosModules.default
    bundle.server
  ];

  networkUnlock.client = {
    enable = true;
    units = ["tailscaled.service"];
    self = {
      internal = "100.105.73.5";
      public = "10.0.0.244";
    };
    peer = {
      internal = "100.105.35.24";
      public = "10.0.0.148";
    };
    luks = {
      crypt = "root_crypt";
      key = "/recovery/root.key";
    };
  };

  lhf = {
    tailscale.autostart.extraTags = ["fleet" "albireo"];
    boot.disk = {
      size.root = "128M";
      devices = [
        {
          path = "/dev/sda";
          size = "100%";
        }
      ];
    };
  };

  # The root is tiny, we need a bigger /tmp for building
  persist.system.directories = ["/tmp"];
  lhf.backup.exclude = ["/nix/pst/tmp"];

  boot = {
    tmp.cleanOnBoot = true; # tmp is persisted for increased capacity
    loader.systemd-boot.configurationLimit = 3;
    initrd.systemd.network = {
      enable = true;
      networks."99-dhcp" = {
        matchConfig.Type = "ether";
        networkConfig.DHCP = "yes";
      };
    };
  };

  zramSwap.memoryPercent = 100;

  networking.useNetworkd = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";
}
