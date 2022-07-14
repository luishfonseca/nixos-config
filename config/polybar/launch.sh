#!/usr/bin/env bash

polybar-msg cmd quit
if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --config=$XDG_CONFIG_HOME/polybar/config.ini example &
  done
else
  polybar --config=$XDG_CONFIG_HOME/polybar/config.ini example &
fi
