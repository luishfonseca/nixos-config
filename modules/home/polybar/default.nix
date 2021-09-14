# modules/home/polybar/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Polybar home configuration.

{ pkgs, ... }:

{
  services.polybar = {
    enable = true;
    script = "polybar main &";

    package = pkgs.polybar.override { pulseSupport = true; };

    settings = {
      "bar/main" = {

        width = "100%";
        height = "40";
        bottom = true;

        padding.left = 2;
        padding.right = 2;

        background = "\${colors.bg1}";
        foreground = "\${colors.fg0}";

        underline.size = 2;

        font = [
          "IBM Plex Sans Cond SmBld:pixelsize=14;3"
          "BlexMono Nerd Font Mono:pixelsize=24;5"
        ];

        tray = {
          position = "left";
          background = "\${colors.bg0}";
          padding = 2;
        };

        modules = {
          center = "bspwm";
          right = "date";
        };
      };

      "module/bspwm" = {
        type = "internal/bspwm";
        pin.workspaces = "true";
        enable.click = "true";

        ws.icon = [ "1;" "2;" "3;" "4;" "5;" "6;" "7;" "8;" "9;" ];

        label-focused = "%icon%";
        label-occupied = "%icon%";
        label-urgent = "%icon%";
        label-empty = "%icon%";

        label.focused = {
          background = "\${colors.bg0}";
          underline = "\${colors.accent}";
          padding = 2;
        };

        label.occupied.padding = 2;

        label.urgent = {
          foreground = "\${colors.red}";
          padding = 2;
        };

        label.empty = {
          foreground = "\${colors.bg2}";
          padding = 2;
        };
      };

      "module/date" = {
        type = "internal/date";
        interval = 5;

        label = "%date% %time%";
        date = "%A, %h %d";
        time = "%I:%M %p";

        format-prefix = "";
        format.prefix = {
          padding = 2;
          foreground = "\${colors.accent}";
        };
      };

      "module/pad" = {
        type = "custom/text";
        content = "   ";
      };
    };
  };
}
