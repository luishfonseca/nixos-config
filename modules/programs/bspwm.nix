{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.programs.bspwm; in
{
  options.lhf.programs.bspwm = {
    enable = mkEnableOption "BSPWM";
    swallow = mkEnableOption "BSPWM swallow";
    colors = let mkColor = name: mkOption {
      description = "Color ${name}";
      default = "#000000";
      type = types.str;
    }; in
      {
        background = mkColor "background";
        background-alt = mkColor "background-alt";
        foreground = mkColor "foreground";
        accent = mkColor "accent";
        disabled = mkColor "disabled";
      };
    desktops = mkOption {
      type = types.listOf types.str;
      default = [ "I" "II" "III" "IV" "V" "VI" ];
      description = "Desktop names";
    };
    sxhkd.binds = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "sxhkd binds";
    };
    polybar = let mkZone = name: {
      tray = mkEnableOption "Polybar tray on ${name}";
      modules = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Polybar ${name} modules";
      };
    }; in
      {
        enable = mkEnableOption "Polybar" // { default = true; };
        height = mkOption {
          type = types.int;
          default = 22;
          description = "Polybar height";
        };
        top = {
          enable = mkEnableOption "Polybar top bar" // { default = true; };
          left = mkZone "left";
          center = mkZone "center";
          right = mkZone "right";
        };
        bottom = {
          enable = mkEnableOption "Polybar bottom bar";
          left = mkZone "left";
          center = mkZone "center";
          right = mkZone "right";
        };
      };
  };

  config =
    let
      edge-switcher = pkgs.writeScriptBin "edge-switcher" ''
        #!/usr/bin/env sh
        function on_exit {
        	for child in $(jobs -p); do
        		jobs -p | grep -q $child && kill $child
        	done
        }

        trap on_exit EXIT SIGHUP SIGINT SIGTERM

        ${pkgs.xdotool}/bin/xdotool behave_screen_edge left exec bspc desktop -f prev & 
        ${pkgs.xdotool}/bin/xdotool behave_screen_edge right exec bspc desktop -f next &
      '';

      bspwmConfig = ''
        #!/usr/bin/env sh
      '' + (if cfg.polybar.enable then ''
        polybar-msg cmd quit
        ${if cfg.polybar.top.enable then "polybar --config=$XDG_CONFIG_HOME/polybar/config.ini top &" else ""}
        ${if cfg.polybar.bottom.enable then "polybar --config=$XDG_CONFIG_HOME/polybar/config.ini bottom &" else ""}
      '' else "") + ''
        bspc monitor -d ${concatStringsSep " " cfg.desktops}

        bspc config border_width         2
        bspc config window_gap           0

        bspc config borderless_monocle   true

        bspc config focused_border_color ${cfg.colors.accent}
        bspc config normal_border_color  ${cfg.colors.disabled}

        ${edge-switcher}/bin/edge-switcher &
      '' + (if cfg.swallow then ''
        export PIDSWALLOW_SWALLOW_COMMAND='bspc node $pwid --flag hidden=on'
        export PIDSWALLOW_VOMIT_COMMAND='bspc node $pwid --flag hidden=off'
        export PIDSWALLOW_PREGLUE_HOOK='bspc query -N -n $pwid.floating >/dev/null && bspc node $cwid --state floating'
        export TERMINAL=.kitty-wrapped #TODO: make it configurable
        ${pkgs.procps}/bin/pgrep -lf 'pidswallow' || ${pkgs.my.pidswallow}/bin/pidswallow -gl &
      '' else "");

      sxhkdConfig = ''
        #!/usr/bin/env sh
        ${concatStringsSep "\n" (mapAttrsToList (k: v: ''
          super + ${k}
            ${v}
        '') cfg.sxhkd.binds)}
      '';

      polybarConfig =
        let common = {
          widht = "100%";
          height = cfg.polybar.height;

          background = cfg.colors.background;
          foreground = cfg.colors.foreground;

          separator = "|";
          separator-foreground = cfg.colors.disabled;

          font-0 = "monospace:size=${toString (cfg.polybar.height - 10)};2";

          enable-ipc = true;

          cursor-click = "pointer";
          cursor-scroll = "ns-resize";

          border-size = 2;
          border-color = cfg.colors.background;
          padding = 1;
          module-margin = 1;

          wm-restack = "bspwm";
        };
        in
        lib.generators.toINI { } {
          "bar/top" = common // {
            bottom = false;

            modules-left = lib.concatStringsSep " " cfg.polybar.top.left.modules;
            modules-center = lib.concatStringsSep " " cfg.polybar.top.center.modules;
            modules-right = lib.concatStringsSep " " cfg.polybar.top.right.modules;

            tray-position =
              if cfg.polybar.top.right.tray then "right"
              else if cfg.polybar.top.center.tray then "center"
              else if cfg.polybar.top.left.tray then "left"
              else "none";
          };

          "bar/bottom" = common // {
            bottom = true;

            modules-left = lib.concatStringsSep " " cfg.polybar.bottom.left.modules;
            modules-center = lib.concatStringsSep " " cfg.polybar.bottom.center.modules;
            modules-right = lib.concatStringsSep " " cfg.polybar.bottom.right.modules;

            tray-position =
              if cfg.polybar.bottom.right.tray then "right"
              else if cfg.polybar.bottom.center.tray then "center"
              else if cfg.polybar.bottom.left.tray then "left"
              else "none";
          };

          "module/bspwm" = {
            type = "internal/bspwm";
            label-focused = "%name%";
            label-focused-background = cfg.colors.background-alt;
            label-focused-underline = cfg.colors.accent;
            label-focused-padding = 1;
            label-unfocused = "%name%";
            label-unfocused-padding = 1;
            label-occupied = "%name%";
            label-occupied-padding = 1;
            label-urgent = "%name%";
            label-urgent-background = cfg.colors.accent;
            label-urgent-padding = 1;
            label-empty = "%name%";
            label-empty-background = cfg.colors.background;
            label-empty-foreground = cfg.colors.disabled;
            label-empty-padding = 1;
          };

          "module/xwindow" = {
            type = "internal/xwindow";
          };

          "module/xkeyboard" = {
            type = "internal/xkeyboard";
            blacklist-0 = "num lock";
            blacklist-1 = "scroll lock";
            label = "%name%";
            label-indicator-foreground = cfg.colors.background;
            label-indicator-background = cfg.colors.accent;
            label-indicator-padding = 1;
          };

          "module/memory" = {
            type = "internal/memory";
            interval = 2;
            format-prefix = "RAM ";
            format-prefix-foreground = cfg.colors.accent;
            label = "%percentage_used:2%%";
          };

          "module/cpu" = {
            type = "internal/cpu";
            interval = 2;
            format-prefix = "CPU ";
            format-prefix-foreground = cfg.colors.accent;
            label = "%percentage:2%%";
          };

          "network-base" = {
            type = "internal/network";
            interval = 5;
            label-disconnected = "";
          };

          "module/wlan" = {
            "inherit" = "network-base";
            interface-type = "wireless";
            label-connected = "%{F${cfg.colors.accent}}%ifname%%{F-} %essid% %local_ip%";
          };

          "module/eth" = {
            "inherit" = "network-base";
            interface-type = "wired";
            label-connected = "%{F${cfg.colors.accent}}%ifname%%{F-} %local_ip%";
          };

          "module/battery" = {
            type = "internal/battery";
            interval = 5;
            low-at = 15;
            label = "%percentage%%";
            label-charging = "%percentage%%";
            label-charging-foreground = cfg.colors.accent;
            label-discharging = "%percentage%%";
            label-discharging-foreground = cfg.colors.foreground;
            label-full = "%percentage%%";
            label-full-foreground = cfg.colors.accent;
            label-low = "%percentage%%";
            label-foreground = cfg.colors.background;
            label-background = cfg.colors.accent;
          };

          "module/date" = {
            type = "internal/date";
            interval = 1;
            date = "%A, %d/%m/%Y";
            time = "%H:%M:%S";
            label = "%date% %time%";
          };
        };
    in
    mkMerge [
      (mkIf cfg.enable {
        services.xserver = {
          enable = true;
          windowManager.bspwm.enable = true;
        };

        hm.xdg.configFile."bspwm/bspwmrc" = {
          text = bspwmConfig;
          executable = true;
        };

        hm.xdg.configFile."sxhkd/sxhkdrc" = {
          text = sxhkdConfig;
          onChange = "pkill -USR1 sxhkd";
        };
      })

      (mkIf cfg.polybar.enable {
        environment.systemPackages = [ pkgs.polybar ];

        hm.xdg.configFile."polybar/config.ini" = {
          text = polybarConfig;
          onChange = "pkill -USR1 polybar";
        };
      })
    ];
}

