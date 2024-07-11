{lib, ...} @ args: let
  listModulesRecursive = dir:
    lib.filter
    (p: lib.hasSuffix ".nix" p)
    (lib.filesystem.listFilesRecursive dir);
in {
  lhf = {inherit listModulesRecursive;} // lib.foldr (path: acc: acc // (import path args)) {} (listModulesRecursive ./.);
}
