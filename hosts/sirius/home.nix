{ pkgs, config, ... }:

{

  imports = [
    ../../modules/home/rofi.nix
    ../../modules/home/alacritty.nix
    ../../modules/home/git.nix
    ../../modules/home/gpg.nix
    ../../modules/home/bspwm.nix
    ../../modules/home/gruvbox.nix
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

  services = {
    picom = {
      enable = true;
      blur = true;
      fade = true;
      inactiveDim = "0.2";
      vSync = true;
    };

    sxhkd = {
      enable = true;
      keybindings = {

        "super + Escape" = "pkill -USR1 -x sxhkd"; # reload sxhkd
      };
    };

    random-background = {
      enable = true;
      imageDirectory = "${../../assets/wallpaper}";
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
