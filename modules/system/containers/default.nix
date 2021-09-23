# modules/system/containers/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Containers configuration.

{ ... }: {
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
}
