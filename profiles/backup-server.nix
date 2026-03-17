{
  publicKeys,
  lib,
  ...
}: {
  services.borgbackup.repos =
    lib.mapAttrs (name: key: {
      path = "/mnt/box/borg/${name}";
      authorizedKeys = [key];
      user = "borg-${name}";
      group = "borg-${name}";
    })
    publicKeys.host;

  users.users = lib.mapAttrs' (name: _:
    lib.nameValuePair "borg-${name}" {extraGroups = ["box"];})
  publicKeys.host;
}
