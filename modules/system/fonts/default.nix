# modules/system/fonts/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Fonts system configuration.

{ pkgs, ... }: {
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "IBMPlexMono" ]; })
      ibm-plex
      noto-fonts-cjk
      noto-fonts-emoji
    ];

    fontconfig.defaultFonts = {
      serif = [ "IBM Plex Serif" "Noto Sans CJK JP" ];
      sansSerif = [ "IBM Plex Sans" "Noto Sans CJK JP" ];
      monospace = [ "BlexMono Nerd Font Mono" "Noto Sans Mono CJK JP" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
