{
  config,
  options,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.lhf.programs.gpg;
in {
  options.lhf.programs.gpg = with types; {
    enable = mkEnableOption "GnuPG";

    sshKeys = mkOption {
      type = nullOr (listOf str);
      default = null;
      description = ''
        Which GPG keys (by keygrip) to expose as SSH keys.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    environment.variables.GNUPGHOME = "$XDG_DATA_HOME/gnupg";

    hm.xdg.dataFile = {
      "gnupg/gpg-agent.conf".text = let
        pinentry-wrapper = pkgs.writeScript "pinentry-wrapper" ''
          #!/bin/sh
          case ${"\"\${PINENTRY_USER_DATA-}\""} in
            *USE_TTY=1*)
              exec ${pkgs.pinentry.tty}/bin/pinentry "$@"
            ;;
          esac
          exec ${pkgs.pinentry.gtk2}/bin/pinentry "$@"
        '';
      in ''
        pinentry-program ${pinentry-wrapper}
      '';

      "gnupg/sshcontrol".text =
        concatMapStrings
        (s: ''
          ${s}
        '')
        cfg.sshKeys;
    };

    environment.interactiveShellInit = ''
      if test -z "$DISPLAY"; then
        export PINENTRY_USER_DATA=USE_TTY=1
      fi
    '';
  };
}
