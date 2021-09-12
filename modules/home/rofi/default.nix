# modules/home/rofi.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Rofi home configuration.

{ pkgs, ... }:

{
  services.sxhkd.keybindings = {
    "super + @space" = "rofi -show drun";
    "super + shift + @space" = "rofi -show run";
  };

  programs.rofi = {
    enable = true;
    terminal = "${pkgs.alacritty}/bin/alacritty";
    extraConfig.modi = "run,drun,ssh";
  };
}
