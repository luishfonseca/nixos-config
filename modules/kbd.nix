{
  config,
  options,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.lhf.kbd;
in {
  options.lhf.kbd = {
    enable = mkEnableOption "kbd";

    package = mkOption {
      type = types.package;
      default = pkgs.kmonad;
      defaultText = "pkgs.kmonad";
      description = "The kmonad package to use.";
    };

    kbdDir = mkOption {
      type = types.path;
      example = "./kbds";
      description = ''
        Directory containing kmonad configuration files.

        Configuration files should not contain the defcfg section and should be named according to the device file:
        /dev/input/by-id/usb-Logitech_USB_Receiver-if02-event-kbd -> ./kbds/id:usb-Logitech_USB_Receiver-if02-event-kbd.kbd
        /dev/input/by-path/platform-i8042-serio-0-event-kbd -> ./kbds/path:platform-i8042-serio-0-event-kbd.kbd
      '';
    };

    composeDelay = mkOption {
      type = types.int;
      default = 5;
      description = "The delay (in milliseconds) between compose key sequences.";
    };

    fallthrough = mkEnableOption "Reemit unhandled key events." // {default = true;};

    allowCommands = mkEnableOption "Allow keys to run shell commands.";
  };

  config = let
    cleanPath = path: removeSuffix ".kbd" (removePrefix "id:" (removePrefix "path:" path));

    expandPath = path:
      if hasPrefix "id:" path
      then "/dev/input/by-id/${cleanPath path}"
      else if hasPrefix "path:" path
      then "/dev/input/by-path/${cleanPath path}"
      else
        throw ''
          Invalid path: ${path}. Paths should be of the form:
          id:usb-Logitech_USB_Receiver-if02-event-kbd.kbd
          path:platform-i8042-serio-0-event-kbd.kbd
        '';
  in
    mkIf cfg.enable {
      services.kmonad = {
        enable = true;
        package = cfg.package;
        keyboards =
          mapAttrs
          (path: _: {
            device = expandPath path;
            name = cleanPath path;
            defcfg = {
              enable = true;
              compose.key = "compose";
              compose.delay = cfg.composeDelay;
              fallthrough = cfg.fallthrough;
              allowCommands = cfg.allowCommands;
            };
            config = builtins.readFile "${cfg.kbdDir}/${path}";
          })
          (builtins.readDir cfg.kbdDir);
      };

      services.xserver.xkb.options = "compose:menu";
    };
}
