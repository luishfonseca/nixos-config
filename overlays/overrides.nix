# overlays/overrides.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Overrides nixpkgs. Useful from getting a pkg from latest.

self: super: {
  inherit (self.latest) neovim;
}
