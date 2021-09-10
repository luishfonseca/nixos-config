{ pkgs, config, ... }:

{

  imports = [
    ../../modules/home/rofi.nix
    ../../modules/home/alacritty.nix
  ];

  home.packages = with pkgs; [
    neofetch
    neovim
    discord
  ];

  programs = {

    firefox.enable = true;

    
    fish = {
      enable = true;
      plugins = [
        {
	  name = "z";
	  src = pkgs.fetchFromGitHub {
            owner = "jethrokuan";
            repo = "z";
	    rev = "45a9ff6d0932b0e9835cbeb60b9794ba706eef10";
	    sha256 = "sha256-pWkEhjbcxXduyKz1mAFo90IuQdX7R8bLCQgb0R+hXs4=";
	  };
	}
      ];
      shellInit = ''
        # Disable greeting
	set -U fish_greeting

        # Use terminal colors
        set -U fish_color_autosuggestion      brblack
        set -U fish_color_cancel              -r
        set -U fish_color_command             brgreen
        set -U fish_color_comment             brmagenta
        set -U fish_color_cwd                 green
        set -U fish_color_cwd_root            red
        set -U fish_color_end                 brmagenta
        set -U fish_color_error               brred
        set -U fish_color_escape              brcyan
        set -U fish_color_history_current     --bold
        set -U fish_color_host                normal
        set -U fish_color_match               --background=brblue
        set -U fish_color_normal              normal
        set -U fish_color_operator            cyan
        set -U fish_color_param               brblue
        set -U fish_color_quote               yellow
        set -U fish_color_redirection         bryellow
        set -U fish_color_search_match        'bryellow' '--background=brblack'
        set -U fish_color_selection           'white' '--bold' '--background=brblack'
        set -U fish_color_status              red
        set -U fish_color_user                brgreen
        set -U fish_color_valid_path          --underline
        set -U fish_pager_color_completion    normal
        set -U fish_pager_color_description   yellow
        set -U fish_pager_color_prefix        'white' '--bold' '--underline'
        set -U fish_pager_color_progress      'brwhite' '--background=cyan'
      '';
    };

    starship = {
      enable = true;
      enableFishIntegration = true;
    };

    ssh = {
      enable = true;
    };

    git = {
      enable = true;
      userName = "Luís Fonseca";
      userEmail = "luis@lhf.pt";
      signing = {
	key = null; # Use the key that matches userEmail
	signByDefault = true;
      };
      extraConfig = {
	init.defaultBranch = "main";
	url."git@github.com".pushinsteadOf = "https://github.com/";
      };
    };

    gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
    };
  };

  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      sshKeys = [ "B155DE05293E0A22B220AB1F8D3414A3E7DED3CF" ];
    };

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
