{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.shell.fish; in
{
  options.lhf.shell.fish = with types; {
    enable = mkEnableOption "Fish Shell";
    isDefault = mkOption { type = bool; default = true; };
    starship.enable = mkEnableOption "Starship";
    anyNixShell.enable = mkEnableOption "Any nix shell";
    direnv.enable = mkEnableOption "Direnv";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.fish.enable = true;
    }
    (mkIf cfg.isDefault {
      users.defaultUserShell = pkgs.fish;
    })
    (mkIf cfg.starship.enable {
      programs.fish.promptInit = ''
        if test "$TERM" != "dumb"
          eval (${pkgs.starship}/bin/starship init fish)
        end
      '';
    })
    (mkIf cfg.anyNixShell.enable {
      programs.fish.promptInit = ''
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      '';
    })
    (mkIf cfg.direnv.enable {
      environment.systemPackages = with pkgs; [
        direnv
        (nix-direnv.override { enableFlakes = true; })
      ];

      nix.extraOptions = ''
        keep-outputs = true
        keep-derivations = true
      '';

      environment.pathsToLink = [
        "/share/nix-direnv"
      ];

      home.file.".direnvrc".text = ''
        source /run/current-system/sw/share/nix-direnv/direnvrc
      '';

      programs.fish.promptInit = ''
        direnv hook fish | source
      '';
    })
  ]);
}
