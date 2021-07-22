{ pkgs, config, ... }:

{

  home.packages = with pkgs; [
    neofetch
    neovim
    neovide
  ];

  programs = {

    firefox.enable = true;

    rofi = let theme_dir = pkgs.fetchFromGitHub {
      owner="bardisty";
      repo="gruvbox-rofi";
      rev="0.3.1";
      sha256="sha256-FcA92YGlNDrhiDXJgVJ5+8CiEmwXka/pMrDOF3rKJ/4=";
    }; in {
      enable = true;
      theme = "${theme_dir}/gruvbox-dark.rasi";
      terminal = "${pkgs.alacritty}/bin/alacritty";
    };

    alacritty = {
      enable = true;
      settings = {
        window = {
          padding = { x = 10; y = 10; };
	  dynamic_padding = true;
	};
        colors = { # gruvbox
          primary = {
            background = "#1d2021";
	    foreground = "#ebdbb2";
	    bright_foreground = "#fbf1c7";
	    dim_foreground = "#a89984";
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
            black   = "#928374";
            red     = "#fb4934";
            green   = "#b8bb26";
            yellow  = "#fabd2f";
            blue    = "#83a598";
            magenta = "#d3869b";
            cyan    = "#8ec07c";
            white   = "#ebdbb2";
	  };
	  normal = {
            black   = "#1d2021";
            red     = "#cc241d";
            green   = "#98971a";
            yellow  = "#d79921";
            blue    = "#458588";
            magenta = "#b16286";
            cyan    = "#689d6a";
            white   = "#a89984";
	  };
	  dim = {
            black   = "#32302f";
            red     = "#9d0006";
            green   = "#79740e";
            yellow  = "#b57614";
            blue    = "#076678";
            magenta = "#8f3f71";
            cyan    = "#427b58";
            white   = "#928374";
	  };
	};
      };
    };
    
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

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    sshKeys = [ "B155DE05293E0A22B220AB1F8D3414A3E7DED3CF" ];
  };

  xdg = {
    enable = true;
    configFile = {
      "sxhkd".source = ../../config/sxhkd;
      "bspwm" = { source = ../../config/bspwm; recursive = true; };
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
