{ pkgs, config, ... }:

{

  imports = [
    ../../modules/home/miscprogs
    ../../modules/home/rofi
    ../../modules/home/alacritty
    ../../modules/home/neovim
    ../../modules/home/chromium

    ../../modules/home/git
    ../../modules/home/gpg
    ../../modules/home/sxhkd
    ../../modules/home/picom

    ../../modules/home/userdirs

    ../../modules/home/bspwm
    ../../modules/home/polybar

    ../../modules/home/gruvbox
    ../../modules/home/wallpaper
  ];

  xdg.enable = true;

  home.stateVersion = "21.05";
}
