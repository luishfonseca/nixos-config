# modules/system/tmpfs_root.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# System config for having root on tmpfs.
# More info here: https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/

{ ... }:
{
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  environment.persistence."/nix/persist".directories = [
    "/var/lib"
    "/var/log"
    "/var/db/sudo/lectured"
  ];

  environment.etc = {
    "/etc/shadow".source = "/nix/persist/etc/shadow";
    "/etc/machine-id".source = "/nix/persist/etc/machine-id";

    "ssh/ssh_host_rsa_key".source = "/nix/persist/etc/ssh/ssh_host_rsa_key";
    "ssh/ssh_host_rsa_key.pub".source = "/nix/persist/etc/ssh/ssh_host_rsa_key.pub";
    "ssh/ssh_host_ed25519_key".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key";
    "ssh/ssh_host_ed25519_key.pub".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key.pub";
  };

  fileSystems."/nix".neededForBoot = true;
}
