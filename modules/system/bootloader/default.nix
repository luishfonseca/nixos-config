# modules/system/bootloader/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Bootloader configuration.

{ ... }: {
  boot.loader = {
    systemd-boot = {
      enable = true;
      editor = false;
    };

    efi.canTouchEfiVariables = true;
  };
}
