{
  profiles,
  modulesPath,
  ...
}: {
  imports = with profiles; [
    bundle.server
    (modulesPath + "/profiles/qemu-guest.nix")
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

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";
}
