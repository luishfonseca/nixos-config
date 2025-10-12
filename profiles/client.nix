{profiles, ...}: {
  imports = [profiles.common] ++ builtins.attrValues profiles._client;
}
