{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.programs.git; in
{
  options.lhf.programs.git.enable = mkEnableOption "Git";

  config = mkIf cfg.enable {
    programs.git.enable = true;
    programs.git.config = {
      init.defaultBranch = "main";
      commit.gpgSign = true;
      url."ssh://git@github.com/".insteadOf = [ "https://github.com/" ];
      user = {
        #TODO: get these from extraArgs
        name = "Luís Fonseca";
        email = "luis@lhf.pt";
      };
    };
  };
}
