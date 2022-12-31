{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.programs.git; in
{
  options.lhf.programs.git.enable = mkEnableOption "Git";

  config.programs.git = mkIf cfg.enable {
    enable = true;
    config = {
      init.defaultBranch = "main";
      commit.gpgSign = true;
      gpg.format = "ssh";
      url."ssh://git@github.com/".insteadOf = [ "https://github.com/" ];
      user = {
        #TODO: these should not be hardcoded
        name = "Luís Fonseca";
        email = "luis@lhf.pt";
        signingkey = config.lhf.services.ssh.user.key;
      };
    };
  };
}
