{lib, ...}: {
  imports = lib.lhf.flattenLeaves (lib.lhf.rakeNixLeaves ./.);
}