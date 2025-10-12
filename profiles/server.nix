{profiles, ...}: {
  imports = [profiles.client] ++ builtins.attrValues profiles._server;
}
