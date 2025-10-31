{
  profiles,
  lib,
  ...
}: {
  imports = [profiles.bundle.common] ++ lib.lhf.flattenLeaves (lib.lhf.rakeNixLeaves ./.);
}
