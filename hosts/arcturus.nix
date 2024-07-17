{profiles, ...}: {
  imports = with profiles; [
    server

    hardware.common-pc
    hardware.common-cpu-amd
  ];

  powerManagement.powertop.enable = true;

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

  user = {
    hashedPassword = "$y$j9T$5/l6lPOfed1cOlPXHeasr/$9IQ0SwrN5KUri5yxCV3HN3.E6mNowwdsLvFacdYuqe/";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE98aQ0VshDOnylLmZcfEdbuxZllCDtfBYH2786f4nph luis@altair"
    ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.05";
}
