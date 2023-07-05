# By Mic92:
# https://github.com/Mic92/dotfiles/blob/c83bcecc32bfd9bc96ba97f518a7e4ccd63393ec/nixos/modules/upgrade-diff.nix

{ pkgs, ... }: {
  system.activationScripts.diff = ''
    ${pkgs.nix}/bin/nix store diff-closures /run/current-system "$systemConfig"
  '';
}
