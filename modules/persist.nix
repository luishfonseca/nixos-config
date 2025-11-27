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

  config = lib.mkMerge [
    {
      environment = {
        persistence."/nix/pst" = lib.mkAliasDefinitions options.persist.system;
        systemPackages = [pkgs.lhf.root-diff];
      };

      systemd.services.root-diff = {
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.lhf.root-diff}/bin/root-diff --capture";
        };
      };

      persist = {
        system = {
          users."${config.user.name}" = lib.mkAliasDefinitions options.persist.home;
          directories = [
            "/var/log"
            "/var/lib/"
          ];
          files = ["/etc/machine-id"];
        };
        home.directories = ["pst"];
      };
    }
    (lib.mkIf (config.time.timeZone == null) {
      # See https://github.com/nix-community/impermanence/issues/153 for context

      boot.postBootCommands = ''
        if test -L /nix/pst/etc/localtime
        then
          ${pkgs.coreutils}/bin/cp -P /nix/pst/etc/localtime /etc/localtime
        fi
      '';

      systemd.services.persist-tz = {
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = [
            "${pkgs.coreutils}/bin/mkdir -p /nix/pst/etc"
            "${pkgs.coreutils}/bin/cp -P /etc/localtime /nix/pst/etc/localtime"
          ];
        };
      };
    })
  ];
}
