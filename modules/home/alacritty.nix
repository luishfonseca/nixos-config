# modules/home/alacritty.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Alacritty home configuration.

{ ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      background_opacity = 0.8;
      window = {
        padding = { x = 10; y = 10; };
        dynamic_padding = true;
      };
      colors = { # gruvbox
        primary = {
          background = "#1d2021";
          foreground = "#ebdbb2";
          bright_foreground = "#fbf1c7";
          dim_foreground = "#a89984";
        };
        cursor = {
          text = "CellBackground";
          cursor = "CellForeground";
        };
        vi_mode_cursor = {
          text = "CellBackground";
          cursor = "CellForeground";
        };
        selection = {
          text = "CellBackground";
          cursor = "CellForeground";
        };
        bright = {
          black   = "#928374";
          red     = "#fb4934";
          green   = "#b8bb26";
          yellow  = "#fabd2f";
          blue    = "#83a598";
          magenta = "#d3869b";
          cyan    = "#8ec07c";
          white   = "#ebdbb2";
        };
        normal = {
          black   = "#1d2021";
          red     = "#cc241d";
          green   = "#98971a";
          yellow  = "#d79921";
          blue    = "#458588";
          magenta = "#b16286";
          cyan    = "#689d6a";
          white   = "#a89984";
        };
        dim = {
          black   = "#32302f";
          red     = "#9d0006";
          green   = "#79740e";
          yellow  = "#b57614";
          blue    = "#076678";
          magenta = "#8f3f71";
          cyan    = "#427b58";
          white   = "#928374";
        };
      };
    };
  };
}
