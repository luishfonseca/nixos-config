{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.programs.gpg; in {
  options.lhf.programs.gpg = with types; {
    enable = mkEnableOption "GnuPG";
    
    sshSupport = {
      enable = mkEnableOption "GnuPG SSH Support";
      keys = mkOption {
        type = nullOr (listOf str);
        default = null;
        description = ''
          Which GPG keys (by keygrip) to expose as SSH keys.
        '';
      };
    };

    pinentryFlavor = mkOption {
      type = nullOr (enum pkgs.pinentry.flavors);
      default = "gtk2";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.gnupg.agent = {
        enable = true;
        pinentryFlavor = cfg.pinentryFlavor;
        enableSSHSupport = cfg.sshSupport.enable;
      };
    
      environment.variables.GNUPGHOME = "$XDG_DATA_HOME/gnupg";
    }
    (mkIf (cfg.sshSupport.keys != null) {
      home.dataFile."gnupg/sshcontrol".text = concatMapStrings (s: ''
        ${s}
      '') cfg.sshSupport.keys;
    })
  ]);
}
