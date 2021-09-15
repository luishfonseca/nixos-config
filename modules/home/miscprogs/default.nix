# modules/home/miscprogs/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Install miscellaneous programs.

{ pkgs, ... }:

{
  home.packages = with pkgs; [ neofetch htop discord ripgrep ];
}
