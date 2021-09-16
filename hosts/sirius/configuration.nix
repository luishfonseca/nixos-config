# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, pkgs, config, hostName, user, ... }:

{

  imports = [
    ./hardware-configuration.nix

    ../../modules/system/tmpfs_root

    ../../modules/system/ssh

    ../../modules/system/rnl

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

  config.boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable the X11 windowing system.
  config.services.xserver.enable = true;

  # Define a user account.
  config.nix.trustedUsers = [ "root" "@wheel" ];
  config.users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    uid = 1000;
  };

  options = with lib; {
    hostName = mkOption { type = types.str; };
    user = mkOption { type = types.str; };
  };
  config = { inherit hostName user; };

  config.system.stateVersion = "21.11";
}

