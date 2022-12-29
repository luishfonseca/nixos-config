{ config, pkgs, ... }:
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "polaris"; # Define your hostname.
  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  services.openssh.enable = true;

  networking.firewall.enable = false;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHgnSKa8CXwWeqAxnkWBASF2tTJ33VylGWI68DAftIsQ"
  ];

  system.stateVersion = "23.05"; # Did you read the comment?

}
