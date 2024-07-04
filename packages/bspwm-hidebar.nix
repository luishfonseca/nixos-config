{
  stdenv,
  lib,
  writeScriptBin,
  coreutils,
  findutils,
  xdo,
  jq,
  bspwm,
}:
writeScriptBin "bspwm-hidebar" ''
  #!/bin/sh

  prev_bar="shown"
  prev_windows="shown"

  ${bspwm}/bin/bspc subscribe node_state desktop_focus desktop_layout | while read -r event; do
    bar="shown"
    windows="shown"

    if ${bspwm}/bin/bspc query -N -n focused.fullscreen; then
      bar="hidden"
      windows="hidden"
    fi

    # in bspwm version 0.9.11 it will be possible to query without jq
    if ${bspwm}/bin/bspc query -T -d | ${jq}/bin/jq -e '.layout == "monocle"'; then
      windows="hidden"
    fi

    if [ "$bar" != "$prev_bar" ]; then
      case "$bar" in
        hidden) ${xdo}/bin/xdo hide -n polybar ;;
        shown) ${xdo}/bin/xdo show -n polybar ;;
      esac
      prev_bar="$bar"
    fi

    if [ "$windows" != "$prev_windows" ]; then
      case "$windows" in
        hidden)
          ${xdo}/bin/xdo id -rd && ${xdo}/bin/xdo id -rd | ${findutils}/bin/xargs -I {} ${bspwm}/bin/bspc node {} --flag hidden=on
          ;;
        shown)
          ${xdo}/bin/xdo id -rd && ${xdo}/bin/xdo id -rd | ${findutils}/bin/xargs -I {} ${bspwm}/bin/bspc node {} --flag hidden=off
          ;;
      esac
      prev_windows="$windows"
    fi

  done
''
