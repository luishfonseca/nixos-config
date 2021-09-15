# modules/system/kbd_layout/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Keyboard layout system configuration.

{ pkgs, ... }: {
  console.useXkbConfig = true;

  services.xserver = {
    layout = "us";
    xkbVariant = "colemak_dh";
    xkbOptions = "ralt:compose";
  };

  services.interception-tools = {
    enable = true;
    plugins = [ pkgs.interception-tools-plugins.caps2esc ];
  };
}

