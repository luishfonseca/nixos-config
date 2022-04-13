{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.shell.fish; in {
  options.lhf.shell.fish.enable = mkEnableOption "Fish Shell";

  config = mkIf cfg.enable {
    users.defaultUserShell = pkgs.fish;

    programs.fish = {
      enable = true;
      promptInit = ''
        if test "$TERM" != "dumb"
          eval (${pkgs.starship}/bin/starship init fish)
        end
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      '';
    };
  };
}
