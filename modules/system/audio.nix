# modules/system/audio.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Sound system configuration.

{ ... }:
{
  sound.enable = true;
  hardware.pulseaudio.enable = true;
}
