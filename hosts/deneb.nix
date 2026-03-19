{
  profiles,
  modulesPath,
  ...
}: {
  imports = with profiles; [
    (modulesPath + "/profiles/qemu-guest.nix")
    bundle.server
  ];

  lhf.boot = {
    tailscale.enable = true;
    disk.devices = [
      {
        path = "/dev/sda";
        size = "100%";
      }
    ];
  };

  boot.loader.systemd-boot.configurationLimit = 5;

  networking.useNetworkd = true;

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.11";
}
