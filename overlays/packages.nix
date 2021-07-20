# overlays/packages.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Extra packages.

self: super: rec {
  pinentry-rofi = super.callPackage ../packages/pinentry-rofi {};
}
