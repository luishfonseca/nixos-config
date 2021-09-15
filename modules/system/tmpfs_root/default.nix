# modules/system/tmpfs_root/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# System config for having root on tmpfs.
# More info here: https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/

{ ... }: {
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  environment.persistence."/nix/persist" = {
    directories = [ "/var/lib" "/var/log" "/var/db/sudo/lectured" ];
    files = [ "/etc/shadow" "/etc/machine-id" ];
  };

  fileSystems."/nix".neededForBoot = true;
}
