{
  config,
  options,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.lhf.programs.tmux;
in {
  options.lhf.programs.tmux.enable = mkEnableOption "tmux";

  config.programs.tmux = mkIf cfg.enable {
    enable = true;
    shortcut = "a";
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    clock24 = true;
  };
}
