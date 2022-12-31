{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.programs.git; in
{
  options.lhf.programs.git = {
    enable = mkEnableOption "Git";
    commits = {
      name = mkOption {
        type = types.str;
        default = "Luís Fonseca";
        description = "Name to use in commits";
      };
      email = mkOption {
        type = types.str;
        default = "luis@lhf.pt";
        description = "Email to use in commits";
      };
      signingkey = mkOption {
        type = types.nullOr types.str;
        default = if config.lhf.services.ssh.enable then config.lhf.services.ssh.user.key else null;
        description = "SSH key to use for signing commits";
      };
    };
  };

  config.programs.git = mkIf cfg.enable (mkMerge [
    {
      enable = true;
      config = {
        init.defaultBranch = "main";
        url."ssh://git@github.com/".insteadOf = [ "https://github.com/" ];
        user = {
          name = cfg.commits.name;
          email = cfg.commits.email;
        };
      };
    }
    (mkIf (cfg.commits.signingkey != null) {
      config = {
        commit.gpgSign = true;
        gpg.format = "ssh";
        user.signingkey = cfg.commits.signingkey;
      };
    })
  ]);
}
