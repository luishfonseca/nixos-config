# modules/home/gruvbox.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Enable gruvbox theme in multiple programs.
# Based on https://github.com/sainnhe/gruvbox-material when possible.

{ pkgs, ... }:

let
  bg0 = "#1d2021";
  bg1 = "#282828";
  bg2 = "#3c3836";
  bg3 = "#594945";
  grey0 = "#7c6f64";
  grey1 = "#928374";
  grey2 = "#a89984";
  fg0 = "#d4be98";
  fg1 = "#ddc7a1";
  red = "#ea6962";
  orange = "#e78a4e";
  yellow = "#d8a657";
  green = "#a9b665";
  aqua = "#89b482";
  blue = "#7daea3";
  purple = "#d3869b";
in {
  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  gtk = {
    enable = true;
    theme = { package = pkgs.gruvbox-dark-gtk; name = "gruvbox-dark"; };
    iconTheme = { package = pkgs.gruvbox-dark-icons-gtk; name = "oomox-gruvbox-dark"; };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  programs.rofi.theme = let theme_dir = pkgs.fetchFromGitHub {
    owner="bardisty";
    repo="gruvbox-rofi";
    rev="0.3.1";
    sha256="sha256-FcA92YGlNDrhiDXJgVJ5+8CiEmwXka/pMrDOF3rKJ/4=";
  }; in "${theme_dir}/gruvbox-dark.rasi";

  programs.alacritty.settings.colors = {
    primary = {
      background = "${bg0}";
      foreground = "${fg0}";
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
      black   = "${bg3}";
      red     = "${red}";
      green   = "${green}";
      yellow  = "${yellow}";
      blue    = "${blue}";
      magenta = "${purple}";
      cyan    = "${aqua}";
      white   = "${fg0}";
    };
    normal = {
      black   = "${bg3}";
      red     = "${red}";
      green   = "${green}";
      yellow  = "${yellow}";
      blue    = "${blue}";
      magenta = "${purple}";
      cyan    = "${aqua}";
      white   = "${fg0}";
    };
  };
}
