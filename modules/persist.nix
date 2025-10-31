{
  config,
  options,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  options.persist = with lib; {
    system = mkOption {type = types.attrs;};
    home = mkOption {type = types.attrs;};
  };

  config = {
    environment = {
      persistence."/nix/pst" = lib.mkAliasDefinitions options.persist.system;
      systemPackages = [pkgs.lhf.root-diff];
    };

    systemd.services.root-diff = {
      wantedBy = ["final.target"];
      before = ["final.target" "unmount.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.lhf.root-diff}/bin/root-diff --capture";
      };
    };

    persist = {
      system = {
        hideMounts = true;
        users."${config.user.name}" = lib.mkAliasDefinitions options.persist.home;
      };
      home.directories = ["pst"];
    };
  };
}
