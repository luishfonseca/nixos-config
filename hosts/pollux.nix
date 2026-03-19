{
  profiles,
  modulesPath,
  ...
}: {
  imports = with profiles; [
    (modulesPath + "/profiles/qemu-guest.nix")
    bundle.server
    exit-node
    storage-box
    backup-server
  ];

  lhf.boot.disk = {
    bios = true;
    encrypt = false;
    devices = [
      {
        path = "/dev/sda";
        size = "100%";
      }
    ];
  };

  boot.loader.systemd-boot.configurationLimit = 5;

  networking.useNetworkd = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";
}
