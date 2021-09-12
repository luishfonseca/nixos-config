# modules/home/userdirs.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# User directories configuration.

{ ... }:

{
  xdg.enable = true;

  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    download = "/tmp/downloads";
    desktop = "\$HOME/desktop";
    documents = "\$HOME/documents";
    music = "\$HOME/music";
    pictures = "\$HOME/pictures";
    publicShare = "\$HOME/public";
    templates = "\$HOME/templates";
    videos = "\$HOME/videos";
  };
}
