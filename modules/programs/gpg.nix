{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.programs.gpg; in {
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

    home.dataFile = {
      "gnupg/gpg-agent.conf".text = ''
        pinentry-program ${pkgs.pinentry.gtk2}/bin/pinentry
      '';

      "gnupg/sshcontrol".text = concatMapStrings (s: ''
        ${s}
      '') cfg.sshKeys;
    };
  };
}
