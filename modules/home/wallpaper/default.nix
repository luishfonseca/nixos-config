# modules/home/wallpaper/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Wallpaper configuration.

{ ... }:

{
  services.random-background = {
    enable = true;
    imageDirectory = "${./imgs}";
  };
}
