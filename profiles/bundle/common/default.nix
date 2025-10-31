{
  profiles,
  lib,
  ...
}: {
  imports = builtins.attrValues (lib.lhf.rakeNixLeaves ./.);
}
