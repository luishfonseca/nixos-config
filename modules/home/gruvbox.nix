# modules/home/gruvbox.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Enable gruvbox theme in multiple programs.
# Based on https://github.com/sainnhe/gruvbox-material when possible.

{ pkgs, ... }:

let
  bg0 = "#070808";
  bg1 = "#131414";
  bg = "#202020";
  bg2 = "#2a2827";
  bg3 = "#2e2c2b";
  bg4 = "#32302f";
  bg5 = "#3d3835";
  bg6 = "#46403d";
  bg7 = "#514945";
  bg8 = "#5a524c";
  bg9 = "#665c54";
  grey0 = "#7c6f64";
  grey1 = "#928374";
  grey2 = "#a89984";
  fg0 = "#ddc7a1";
  fg = "#d4be98";
  fg1 = "#c5b18d";
  red = "#ea6962";
  orange = "#e78a4e";
  yellow = "#d8a657";
  green = "#a9b665";
  aqua = "#89b482";
  blue = "#7daea3";
  purple = "#d3869b";
  dimRed = "#b85651";
  dimOrange = "#bd6f3e";
  dimYellow = "#c18f41";
  dimGreen = "#8f9a52";
  dimAqua = "#72966c";
  dimBlue = "#68948a";
  dimPurple = "#ab6c7d";
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
      foreground = "${fg}";
      bright_foreground = "${fg0}";
      dim_foreground = "${fg1}";
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
      black   = "${bg}";
      red     = "${red}";
      green   = "${green}";
      yellow  = "${yellow}";
      blue    = "${blue}";
      magenta = "${purple}";
      cyan    = "${aqua}";
      white   = "${fg}";
    };
    normal = {
      black   = "${bg1}";
      red     = "${dimRed}";
      green   = "${dimGreen}";
      yellow  = "${dimYellow}";
      blue    = "${dimBlue}";
      magenta = "${dimPurple}";
      cyan    = "${dimAqua}";
      white   = "${fg1}";
    };
  };
}
