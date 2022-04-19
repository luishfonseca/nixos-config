{ config, pkgs, lib, ... }:

with lib;
{
  programs.slock.enable = true;

  fonts = {
    fonts = with pkgs;
      [
        (nerdfonts.override { fonts = [ "IBMPlexMono" ]; })
        ibm-plex
        noto-fonts-emoji
      ];

    fontconfig.defaultFonts = {
      serif = [ "IBM Plex Serif" "IBM Plex Sans JP" ];
      sansSerif = [ "IBM Plex Sans" "IBM Plex Sans JP" ];
      monospace = [ "BlexMono Nerd Font Mono" "IBM Plex Sans JP" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
