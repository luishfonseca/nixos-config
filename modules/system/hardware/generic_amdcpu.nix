# modules/system/hardware/generic_amdcpu.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Generic AMD CPU system configuration.

{ config, ... }:
{
  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
}
