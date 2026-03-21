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

  lhf.boot = {
    tailscale.enable = true;
    mutualUnlock = {
      enable = true;
      wants = ["tailscaled.service"];
      self = {
        internal = "100.123.137.111";
        external = "178.104.72.93";
      };
      peer = {
        internal = "100.105.35.24";
        public = "158.178.156.3";
      };
    };
    disk = {
      bios = true;
      devices = [
        {
          path = "/dev/sda";
          size = "100%";
        }
      ];
    };
  };

  boot.loader.systemd-boot.configurationLimit = 3;

  networking.useNetworkd = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";
}
