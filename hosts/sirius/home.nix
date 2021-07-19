{ pkgs, config, ... }:

{

  home.packages = with pkgs; [
    neofetch
    neovim
    neovide
  ];

  programs = {

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
          padding = { x = 15; y = 15; };
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
    
    starship = {
      enable = true;
      enableZshIntegration = true;
    };

    zsh = {
      enable = true;
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
  };

  xdg = {
    enable = true;
    configFile = {
      "sxhkd".source = ../../config/sxhkd;
      "bspwm" = { source = ../../config/bspwm; recursive = true; };
    };
  };

  home.file."${config.programs.gpg.homedir}/sshcontrol".text = ''
    B155DE05293E0A22B220AB1F8D3414A3E7DED3CF
  '';

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
