{ config, options, lib, inputs, ... }:
with lib;
let cfg = config.lhf.tmpfsRoot;
in
{
  options.lhf.tmpfsRoot.enable = mkEnableOption "Tmpfs Root";

  config = mkIf cfg.enable {
    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=2G" "mode=755" ];
    };

    environment.persistence."/nix/persist" = {
      directories =
        [ "/var/lib" "/var/log" "/var/db/sudo/lectured" "/etc/nixos" "/etc/NetworkManager/system-connections" ];
      files = [ "/etc/machine-id" "/etc/ssh/ssh_host_ed25519_key" "/etc/wireguard/gsd.key" ];
    };

    fileSystems."/nix".neededForBoot = true;
  };
}
