{ pkgs, config, ... }:

{

  programs = {
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
