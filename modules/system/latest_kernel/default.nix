# modules/system/latest_kernel/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Use latest kernel.

{ pkgs, ... }: {
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
