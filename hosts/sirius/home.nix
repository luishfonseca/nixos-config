{ pkgs, config, ... }:

{

  imports = [
    ../../modules/home/rofi.nix
    ../../modules/home/alacritty.nix

    ../../modules/home/git.nix
    ../../modules/home/gpg.nix
    ../../modules/home/sxhkd.nix
    ../../modules/home/picom.nix

    ../../modules/home/bspwm.nix

    ../../modules/home/gruvbox.nix
    ../../modules/home/wallpaper.nix
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

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.stateVersion = "21.05";
}
