{
  profiles,
  lib,
  ...
}: {
  imports = [profiles.bundle.common] ++ builtins.attrValues (lib.lhf.rakeNixLeaves ./.);
}
