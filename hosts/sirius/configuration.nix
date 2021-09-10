# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{

  imports = [
      ./hardware-configuration.nix

      ../../modules/system/tmpfs_root.nix

      ../../modules/system/shell.nix
      ../../modules/system/bootloader.nix
      ../../modules/system/fonts.nix
      ../../modules/system/gtk.nix
      ../../modules/system/kbd_layout.nix
      ../../modules/system/lightdm.nix
      ../../modules/system/audio.nix
      ../../modules/system/network.nix

      ../../modules/system/steam.nix

      ../../modules/system/hardware/generic_amdgpu.nix
      ../../modules/system/hardware/generic_amdcpu.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "sirius"; # Define your hostname.

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Define a user account.
  nix.trustedUsers = [ "root" "@wheel" ];
  users.users.luis = {
    initialPassword = "changeme";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  system.stateVersion = "21.11";
}

