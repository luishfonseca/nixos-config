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
    mutualUnlock = {
      enable = true;
      wants = ["tailscaled.service"];
      self = {
        internal = "100.105.35.24";
        external = "10.0.0.148"; # oracle cloud does nat 1:1
        public = "158.178.156.3";
      };
      peer = {
        internal = "100.123.137.111";
        public = "178.104.72.93";
      };
    };
    disk.devices = [
      {
        path = "/dev/sda";
        size = "100%";
      }
    ];
  };

  boot.loader.systemd-boot.configurationLimit = 3;

  networking.useNetworkd = true;

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.11";
}
