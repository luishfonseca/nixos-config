{profiles, ...}: {
  imports = builtins.attrValues profiles._common;
}
