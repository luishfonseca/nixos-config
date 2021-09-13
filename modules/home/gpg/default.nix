# modules/home/gpg/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# GPG home configuration.

{ config, ... }:

{
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
    settings = {
      default-key = "0xA79367D3D8F78AAD!";
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    sshKeys = [ "B155DE05293E0A22B220AB1F8D3414A3E7DED3CF" ];
  };
}
