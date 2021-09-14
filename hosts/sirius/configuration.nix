# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{

  imports = [
    ./hardware-configuration.nix

    ../../modules/system/tmpfs_root

    ../../modules/system/shell
    ../../modules/system/bootloader
    ../../modules/system/fonts
    ../../modules/system/gtk
    ../../modules/system/kbd_layout
    ../../modules/system/audio
    ../../modules/system/network

    ../../modules/system/autologin
    ../../modules/system/hm-session

    ../../modules/system/steam

    ../../modules/system/hardware/generic_amdgpu
    ../../modules/system/hardware/generic_amdcpu
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "sirius"; # Define your hostname.

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Define a user account.
  nix.trustedUsers = [ "root" "@wheel" ];
  users.users.luis = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  system.stateVersion = "21.11";
}

