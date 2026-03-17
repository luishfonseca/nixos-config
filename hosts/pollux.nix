{
  profiles,
  modulesPath,
  ...
}: {
  imports = with profiles; [
    (modulesPath + "/profiles/qemu-guest.nix")
    bundle.server
    exit-node
  ];

  lhf.boot.disk = {
    bios = true;
    encrypt = false;
    devices = [
      {
        id = "scsi-0QEMU_QEMU_HARDDISK_113867753";
        size = "100%";
      }
    ];
  };

  networking.useNetworkd = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";
}
