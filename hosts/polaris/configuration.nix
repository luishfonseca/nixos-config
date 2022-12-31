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

  user.hashedPassword = "$6$fVkVAZBekeB.32U2$Pv6rLCSpeS/CPqXbkRXVolbzeRLlxDUEZ4IsGE.Q1jQ526J5nKT9fVReDu3dyg/An4Qn7zE83vJoKvQIn0EWV/";
  users.mutableUsers = false;

  lhf.services.ssh = {
    enable = true;
    host.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFTBIsgb2YNXL3EouuaJSXS1p9YFGng+VkunpcWmu9Ke";
    user.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILNztXCOFqjBvL3swizvbfvLtynt6XEHT4uLo4D2Z6vU";
    manageKnownHosts = true;
    manageSSHLogin = true;
    allowSSHAgentAuth = true;
  };

  networking.firewall.enable = false;

  lhf.powerSaving.enable = true;

  lhf.shell.fish = {
    enable = true;
    starship.enable = true;
    anyNixShell.enable = true;
    direnv.enable = true;
  };

  lhf.shell.dash = {
    enable = true;
    isSystemDefault = true;
  };

  services.tailscale.enable = true;

  system.stateVersion = "22.11";
}
