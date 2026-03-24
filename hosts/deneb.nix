{
  inputs,
  config,
  pkgs,
  profiles,
  modulesPath,
  ...
}: {
  imports = with profiles; [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.network-unlock.nixosModules.default
    bundle.server
  ];

  # deneb:WVbL9VL8s2wXdDz+rV+ZVO8zh4vO1CCgTLfa7q9FGuI=
  pasta.endpoints.cache = "http://deneb:5000";
  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    secretKeyFile = config.sops.secrets.binary-cache-key.path;
  };

  boot.initrd.systemd.network = {
    enable = true;
    networks."99-dhcp" = {
      matchConfig.Type = "ether";
      networkConfig.DHCP = "yes";
    };
  };

  networkUnlock = rec {
    server = {
      enable = true;
      openFirewall = true;
      internal = "100.105.35.24";
      external = "10.0.0.148"; # oracle cloud does nat 1:1
      public = "158.178.156.3";
    };
    client = {
      enable = true;
      units = ["tailscaled.service"];
      self = {
        inherit (server) internal public;
      };
      peer = {
        internal = "100.123.137.111";
        public = "178.104.72.93";
      };
      luks = {
        crypt = "root_crypt";
        key = "/recovery/root.key";
      };
    };
  };

  lhf.boot.disk.devices = [
    {
      path = "/dev/sda";
      size = "100%";
    }
  ];

  boot.loader.systemd-boot.configurationLimit = 3;

  networking.useNetworkd = true;

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.11";
}
