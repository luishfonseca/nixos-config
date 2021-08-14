# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{

  imports = [
      ./hardware-configuration.nix
      
      ../../modules/system/bootloader.nix
      ../../modules/system/fonts.nix
      ../../modules/system/gtk.nix
      ../../modules/system/kbd_layout.nix
      ../../modules/system/lightdm.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "sirius"; # Define your hostname.
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

  networking.useDHCP = false;
  networking.interfaces.enp35s0.useDHCP = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    videoDrivers = [ "amdgpu" ];
    
  };

  # Define a user account.
  nix.trustedUsers = [ "root" "@wheel" ];
  users.defaultUserShell = pkgs.fish;
  users.users.luis = {
    initialPassword = "123";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  system.stateVersion = "21.11";
}

