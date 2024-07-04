{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.programs.vscode; in
{
  options.lhf.programs.vscode = with types; {
    enable = mkEnableOption "Visual Studio Code";
    extensions = mkOption { type = listOf package; default = [ ]; };
  };

  config = mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;
    environment.systemPackages = with pkgs.unstable; [
      (vscode-with-extensions.override {
        vscodeExtensions = cfg.extensions;
      })
    ];
  };
}
