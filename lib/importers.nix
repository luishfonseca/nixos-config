{lib, ...}: let
  /*
  *
  Synopsis: rakeNixLeaves _path_

  Recursively collect the nix files of _path_ into attrs.

  Output Format:
  An attribute set where all `.nix` files and directories with `default.nix` in them
  are mapped to keys that are either the file with .nix stripped or the folder name.
  All other directories are recursed further into nested attribute sets with the same format.

  Example file structure:
  ```
  ./core/default.nix
  ./base.nix
  ./main/dev.nix
  ./main/os/default.nix
  ```

  Example output:
  ```
  {
    core = ./core;
    base = ./base.nix;
    main = {
      dev = ./main/dev.nix;
      os = ./main/os;
    };
  };
  ```

  *
  */
  rakeNixLeaves = rakeLeaves (lib.hasSuffix ".nix");

  rakeAllLeaves = rakeLeaves (_: true);

  rakeLeaves = sieve: dirPath: let
    f = file: type:
      (type == "directory")
      || (type == "regular")
      && (file != "default.nix")
      && (sieve file);

    collect = file: type: {
      name = lib.removeSuffix ".nix" file;
      value = let
        path = dirPath + "/${file}";
      in
        if
          (type == "directory")
          && (builtins.pathExists (path + "/default.nix"))
          || (type == "regular")
        then path
        # recurse on directories that don't contain a `default.nix`
        else rakeLeaves sieve path;
    };

    files = lib.filterAttrs f (builtins.readDir dirPath);
  in
    lib.filterAttrs (_: v: v != {}) (lib.mapAttrs' collect files);
in {
  inherit rakeNixLeaves rakeAllLeaves;
}
