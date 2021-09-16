# modules/home/git/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Git home configuration.

{ ... }:

{
  programs.git = {
    enable = true;
    userName = "Luís Fonseca";
    userEmail = "luis@lhf.pt";
    signing = {
      key = null; # Use the key that matches userEmail
      signByDefault = true;
    };
    extraConfig = {
      init.defaultBranch = "main";
      url."ssh://git@github.com/".pushinsteadOf = "https://github.com/";
    };
  };
}
