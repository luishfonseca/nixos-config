# modules/home/rofi.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Rofi home configuration.

{ pkgs, ... }:

{
  programs.rofi = let theme_dir = pkgs.fetchFromGitHub {
    owner="bardisty";
    repo="gruvbox-rofi";
    rev="0.3.1";
    sha256="sha256-FcA92YGlNDrhiDXJgVJ5+8CiEmwXka/pMrDOF3rKJ/4=";
  }; in {
    enable = true;
    theme = "${theme_dir}/gruvbox-dark.rasi";
    terminal = "${pkgs.alacritty}/bin/alacritty";
  };
}
