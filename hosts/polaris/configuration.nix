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
    allowSSHAgentAuth = true;
    manageKnownHosts.enable = true;
    manageSSHAuthKeys = {
      enable = true;
      extraKeys."luis@vega" = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBI51YbPjEZ/NGZ+ibWmyencNqZ1YYX111SIuPUzidGEMaT0oUYRPdLmRczgW3HPCoNpgV9Png0OFivDCJbPYhXo=";
    };
  };

  networking.domain = "in.lhf.pt";

  lhf.services.dnsovertlsProxy = {
    enable = true;
    name = "ns.lhf.pt";
    ip = "146.59.158.114";
  };

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

  users.groups.media.members = [
    config.user.name
    config.services.transmission.user
  ];

  services.transmission = {
    enable = true;
    group = "media";

    performanceNetParameters = true;
    downloadDirPermissions = "770";

    settings = {
      watch-dir-enabled = true;
      trash-original-torrent-files = true;
      download-dir = "/media/downloads";
      incomplete-dir = "/media/downloads/.incomplete";

      rpc-bind-address = "::1";
      rpc-host-whitelist = "::1";
      rpc-host-whitelist-enabled = true;

      peer-limit-global = 500;
      peer-limit-per-torrent = 50;

      encryption = 2;

      start-added-torrents = true;
    };
  };

  lhf.services.flood = {
    enable = true;
    bind = "0.0.0.0";
    transmission = {
      enable = true;
      url = "http://[::1]:9091/transmission/rpc";
    };
  };

  services.tailscale.enable = true;

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    checkReversePath = "loose";
  };

  system.stateVersion = "22.11";
}
