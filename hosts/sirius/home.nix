{ pkgs, config, ... }:

{

  imports = [
    ../../modules/home/rofi
    ../../modules/home/alacritty
    ../../modules/home/neovim

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

  home.packages = with pkgs; [
    neofetch
    neovim
    discord
  ];

  programs = {
    firefox.enable = true;

    ssh = {
      enable = true;
    };
  };

  xdg.enable = true;

  home.keyboard = {
    layout = "us";
    variant = "colemak_dh";
    options = [ "ralt:compose" ];
  };

  home.stateVersion = "21.05";
}
