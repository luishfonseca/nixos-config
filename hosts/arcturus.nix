{profiles, ...}: {
  imports = with profiles; [
    server

    hardware.common-pc
    hardware.common-cpu-amd
  ];

  lhf.fsRoot = {
    device = {
      path = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_500GB_S4EVNS0WB10632A";
      ssd = true;
    };
    encryption = {
      enable = true;
      tpm = true;
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.05";
}
