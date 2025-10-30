{
  inputs,
  config,
  pkgs,
  ...
}:
with inputs.nix-colors.colorSchemes.dracula; {
  security.rtkit.enable = true;

  services = {
    upower.enable = true;
    power-profiles-daemon.enable = true;
    pipewire = {
      enable = true;
      wireplumber.enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };

  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
      package = pkgs.unstable.hyprland;
      portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;
    };
    dconf.profiles.user.databases = [
      {
        lockAll = true;
        settings = {
          "org/gnome/desktop/interface".color-scheme = "prefer-dark";
        };
      }
    ];
  };

  environment.loginShellInit = ''
    if uwsm check may-start; then
      exec uwsm start hyprland-uwsm.desktop
    fi
  '';

  hm = {
    home = {
      shellAliases.ssh = "kitten ssh"; # Sends terminfo to remote host

      pointerCursor = {
        enable = true;
        package = pkgs.vanilla-dmz;
        name = "Vanilla-DMZ";
        size = 24;
        gtk.enable = true;
        hyprcursor.enable = true;
      };

      packages = with pkgs; [
        qt5.qtwayland
        qt6.qtwayland
        wl-clipboard
        unstable.ashell
        pavucontrol
        networkmanagerapplet
        brightnessctl
      ];
    };

    programs = {
      hyprlock.enable = true;
      wofi.enable = true;
      kitty = {
        enable = true;
        settings = {
          confirm_os_window_close = 0;
          scrollback_lines = 10000;
          hide_window_decorations = "yes";
          notify_on_cmd_finish = "invisible 20";
        };
      };
    };

    services = {
      dunst = {
        enable = true;
        package = pkgs.unstable.dunst;
      };
      hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on && brightnessctl -r";
          };

          listener = [
            {
              timeout = 120; # 2 min
              on-timeout = "brightnessctl -s set 1%";
              on-resume = "brightnessctl -r";
            }
            {
              timeout = 150; # 2.5 min
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 180; # 3 min
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
            {
              timeout = 600; # 10 min
              on-timeout = "systemctl sleep";
            }
          ];
        };
      };
      hyprpolkitagent.enable = true;
      cliphist.enable = true;
    };

    gtk.enable = true;

    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;

      settings = {
        "$mod" = "SUPER";
        "$run" = "uwsm app --";
        "$term" = "kitty --single-instance";
        "$bar" = "ashell";
        "$menu" = "wofi";

        env = [
          "NIXOS_OZONE_WL,1"
        ];

        input = with config.services.xserver.xkb; {
          kb_rules = "evdev";
          kb_model = model;
          kb_layout = layout;
          kb_variant = variant;
          kb_options = options;
          natural_scroll = true;
        };

        general = {
          gaps_in = 0;
          gaps_out = 0;
        };

        animations.enabled = false;

        decoration = {
          blur.enabled = false;
          shadow.enabled = false;
        };

        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          enable_swallow = true;
          swallow_regex = "^(kitty)$";
        };

        dwindle = {
          preserve_split = true;
          precise_mouse_move = true;
        };

        exec-once = [
          "$run $term --start-as=hidden"
          "$run $bar"
        ];

        gesture = [
          "3, horizontal, workspace"
          "3, up, dispatcher, workspace, emptym"
          "3, down, dispatcher, workspace, 1"

          "3, swipe, mod: $mod, move"
          "3, swipe, mod: $mod SHIFT, resize"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod SHIFT, mouse:272, resizewindow"
        ];

        bind = [
          "$mod, Return, exec, $run $term"
          "$mod, Space, exec, $run $menu --show drun"
          "$mod, V, exec, $run cliphist list | wofi --show dmenu | cliphist decode | wl-copy"

          "$mod, W, killactive"
          "$mod, Q, exec, uwsm stop"
          "$mod, F, fullscreen"
          "$mod, P, togglefloating"
          "$mod, R, layoutmsg, movetoroot"

          "$mod, S, togglespecialworkspace, scratch"
          "$mod SHIFT, S, movetoworkspace, special:scratch"

          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, down, movefocus, d"
          "$mod, up, movefocus, u"

          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"
          "$mod, 0, workspace, 10"

          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"
          "$mod SHIFT, 0, movetoworkspace, 10"
        ];

        windowrule = [
          "suppressevent maximize, class:.*"
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        ];
      };
    };

    xdg.configFile."ashell/config.toml".text = ''
      outputs = "Active"

      [appearance]
      style = "Solid"
      opacity = 1.0
      background_color = "#${palette.base00}"

      [settings]
      logout_cmd = "uwsm stop"
      suspend_cmd = "systemctl sleep"
      audio_sinks_more_cmd = "uwsm app -- pavucontrol -t 3"
      audio_sources_more_cmd = "uwsm app -- pavucontrol -t 4"
      wifi_more_cmd = "uwsm app -- nm-connection-editor"
      vpn_more_cmd = "uwsm app -- nm-connection-editor"
      bluetooth_more_cmd = "uwsm app -- blueman-manager"
      remove_airplane_btn = true
    '';
  };
}
