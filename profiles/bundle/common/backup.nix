{config, ...}: let
  hostname = config.networking.hostName;
in {
  lhf.backup = {
    enable = true;
    exclude = ["/nix/pst/var/log"];
    repo = "borg-${hostname}@pollux:/mnt/box/borg/${hostname}";
  };
}
