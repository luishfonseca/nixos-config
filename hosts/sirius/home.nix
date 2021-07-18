{ pkgs, ... }:

{

  programs.git = {
    enable = true;
    userName = "Luís Fonseca";
    userEmail = "luis@lhf.pt";
  };

  xdg.enable = true;
  xdg.configFile = {
    "sxhkd" = { source = ../../config/sxhkd; recursive = true; };
    "bspwm" = { source = ../../config/bspwm; recursive = true; };
  };

}
