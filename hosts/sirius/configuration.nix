# hosts/sirius/configuration.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Sirius system configuration.

{ lib, config, hostName, user, ... }:

{

  imports = [
    ./hardware-configuration.nix

    ../../modules/system/tmpfs_root

    ../../modules/system/ssh
    ../../modules/system/syncthing

    ../../modules/system/rnl

    ../../modules/system/shell
    ../../modules/system/bootloader
    ../../modules/system/fonts
    ../../modules/system/gtk
    ../../modules/system/kbd_layout
    ../../modules/system/audio
    ../../modules/system/network
    ../../modules/system/containers

    ../../modules/system/autologin
    ../../modules/system/hm-session

    ../../modules/system/steam

    ../../modules/system/latest_kernel
  ];

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

