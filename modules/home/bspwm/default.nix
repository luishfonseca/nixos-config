# modules/home/bspwm/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# BSPWM home configuration.

{ lib, ... }:

{
  xsession = {
    enable = true;
    windowManager.bspwm = {
      enable = true;
      monitors.primary = with lib; forEach (range 1 9) (x: toString x);
    };
  };

  services.sxhkd.keybindings = {

    # general

    "super + shift + {q,r}" = "bspc {quit,wm -r}"; # quit/restart bspwm
    "super + {_,shift + }c" = "bspc node -{c,k}"; # close/kill node
    "super + m" = "bspc desktop -l next"; # toggle monocle layout
    "super + g" = "bspc node -s biggest.window"; # swap with biggest

    # focus/swap

    "super + {_,shift + }{h,j,k,l}" =
      "bspc node -{f,s} {west,south,north,east}"; # direction
    "super + {p,b,comma,period}" =
      "bspc node -f @{parent,brother,first,second}"; # path

    # focus/send node to workspace
    "super + {_,shift +}{1-9}" = "bspc {desktop -f,node -d} {1-9}";

    # resize

    "super + alt + {h,j,k,l}" =
      "bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}"; # expand
    "super + alt + shift + {h,j,k,l}" =
      "bspc node -z {right -20 0,top 0 20,bottom 0 -20,left 20 0}"; # contract

  };
}
