{ pkgs, config, ... }:

{

  imports = [
    ../../modules/home/rofi.nix
    ../../modules/home/alacritty.nix
    ../../modules/home/git.nix
    ../../modules/home/gpg.nix
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

        # wm independent hotkeys

        "super + Return" = "alacritty"; # terminal emulator
        "super + @space" = "rofi -show run"; # program launcher
        "super + Escape" = "pkill -USR1 -x sxhkd"; # reload sxhkd


        # bspwm hotkeys

        "super + shift + {q,r}" = "bspc {quit,wm -r}"; # quit/restart bspwm
        "super + {_,shift + }c" = "bspc node -{c,k}"; # close/kill node
        "super + m"             = "bspc desktop -l next"; # toggle monocle layout
        "super + g"             = "bspc node -s biggest.window"; # swap with biggest


        # focus/swap

        "super + {_,shift + }{h,j,k,l}" = "bspc node -{f,s} {west,south,north,east}"; # direction
        "super + {p,b,comma,period}"    = "bspc node -f @{parent,brother,first,second}"; # path


        # resize

        "super + alt + {h,j,k,l}"         = "bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}"; # expand
        "super + alt + shift + {h,j,k,l}" = "bspc node -z {right -20 0,top 0 20,bottom 0 -20,left 20 0}"; # contract
      };
    };

    random-background = {
      enable = true;
      imageDirectory = "${../../assets/wallpaper}";
    };
  };

  xdg.enable = true;

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

  xsession = {
    enable = true;
    windowManager.bspwm.enable = true;
  };

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
