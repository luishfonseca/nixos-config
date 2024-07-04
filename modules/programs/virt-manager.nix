{
  config,
  options,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.lhf.programs.virtManager;
in {
  options.lhf.programs.virtManager = with types; {
    enable = mkEnableOption "Virt Manager";
    autoconnectAll = mkOption {
      type = bool;
      default = true;
    };
    connections = mkOption {
      type = listOf str;
      default = [];
    };
  };

  config = mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMF.override {
              secureBoot = true;
              tpmSupport = true;
            })
            .fd
          ];
        };
      };
    };

    networking.firewall.trustedInterfaces = ["virbr0"];

    environment.systemPackages = with pkgs; [virt-manager];

    programs.dconf.enable = true;
    system.userActivationScripts.virtManager.text = let
      connections = ["qemu:///system"] ++ cfg.connections;
      formatConnections = conns: "[${strings.concatMapStringsSep ", " (s: "'${s}'") conns}]";
    in ''
      ${pkgs.dconf}/bin/dconf load / << EOF
      [org/virt-manager/virt-manager/connections]
      uris=${formatConnections connections}
      ${
        if cfg.autoconnectAll
        then "autoconnect=${formatConnections connections}"
        else ""
      }
      EOF
    '';

    user.extraGroups = ["libvirtd"];
  };
}
