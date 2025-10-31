{profiles, ...}: {
  imports = builtins.attrValues profiles._dev;
}
