{
  profiles,
  modulesPath,
  ...
}: {
  imports = with profiles; [
    (modulesPath + "/profiles/qemu-guest.nix")
    bundle.server
  ];

  lhf.boot.disk = {
    encrypt = false;
    devices = [
      {
        id = "wwn-0x6081867f28a2406a98cf33a5dbfcd450";
        size = "100%";
      }
    ];
  };

  networking.useNetworkd = true;

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.11";
}
