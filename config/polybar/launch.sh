#!/usr/bin/env bash

polybar-msg cmd quit
polybar --config=$XDG_CONFIG_HOME/polybar/config.ini example &
