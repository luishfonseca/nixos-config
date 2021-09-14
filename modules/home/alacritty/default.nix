# modules/home/alacritty/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Alacritty home configuration.

{ ... }:

{
  services.sxhkd.keybindings = { "super + Return" = "alacritty"; };

  programs.alacritty = {
    enable = true;
    settings = {
      background_opacity = 0.85;
      window = {
        padding = {
          x = 10;
          y = 10;
        };
        dynamic_padding = true;
      };
    };
  };
}
