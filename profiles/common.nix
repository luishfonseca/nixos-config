{profiles, ...}: {
  imports = builtins.attrValues profiles._common;

  user.name = "luis";
}
