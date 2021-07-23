# overlays/overrides.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Overrides nixpkgs. Useful from getting a pkg from latest.

self: super: {
  inherit (self.unstable) neovim;
  inherit (self.unstable) xkeyboard_config; # Version 2.33 is needed for colemak_dh
  inherit (self.latest) discord; # Will soft lock trying to get latest version
}
