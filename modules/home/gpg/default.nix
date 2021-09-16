# modules/home/gpg/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# GPG home configuration.

{ config, ... }:
let
  hosts = {
    altair = {
      default-key = "0x1F5F4034CC1D1969!";
      sshKeys = [ "DB4E50598EBC42BC801BBEC6C39A9A399FD27081" ];
    };
    sirius = {
      default-key = "0xA79367D3D8F78AAD!";
      sshKeys = [ "B155DE05293E0A22B220AB1F8D3414A3E7DED3CF" ];
    };
    procyon = {
      default-key = "0x428DB995B1EFE4FA!";
      sshKeys = [ "A8329FD9836E2DF1DB5820200DC3CFF29680124E" ];
    };
  };
in {
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
    settings = { inherit (hosts.${config.hostName}) default-key; };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    inherit (hosts.${config.hostName}) sshKeys;
  };
}
