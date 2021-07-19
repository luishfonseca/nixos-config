{ pkgs, ... }:

{

  programs.git = {
    enable = true;
    userName = "Luís Fonseca";
    userEmail = "luis@lhf.pt";
  };

  xdg = {
    enable = true;
    configFile = {
      "sxhkd".source = ../../config/sxhkd;
      "bspwm" = { source = ../../config/bspwm; recursive = true; };
    };
  };

}
