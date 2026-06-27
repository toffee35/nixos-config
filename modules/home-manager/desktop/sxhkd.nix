{
  lib,
  homedir,
  ...
}: {
  home.activation.createScreensDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${homedir}/Screens
  '';

  services.sxhkd = {
    enable = true;

    keybindings = {
      "ctrl + alt + r" = "pkill -USR1 -x sxhkd && bspc wm -r";
      "ctrl + alt + q" = "bspc quit";
      "ctrl + alt + Escape" = "pkill -USR1 -x sxhkd";

      "super + Return" = "alacritty";
      "super + r" = "rofi -show drun";
      "super + e" = "thunar";
      "super + v" = "CM_LAUNCHER=rofi clipmenu";
      "super + p" = "xcolor -S 12 -s clipboard";

      "XF86MonBrightness{Down,Up}" = "brightnessctl set {10%-,+10%}";
      "XF86Audio{Lower,Raise}Volume" = "pamixer {-d,-i} 10";
      "@Print" = "scrot -z ${homedir}/Screens/%Y-%m-%d_%H-%M-%S.png";
      "super + Print" = "scrot -s -f -z ${homedir}/Screens/%Y-%m-%d_%H-%M-%S.png";

      "super + {_,shift + }q" = "bspc node -{c,k}";
      "super + {t,f,shift + f}" = "bspc node -t {tiled,floating,fullscreen}";
      "super + s" = "bspc node -g sticky";

      "super + {1-9,0}" = "bspc desktop -f '^{1-9,10}'";
      "super + shift + {1-9,0}" = "bspc node -d '^{1-9,10}'";

      "super + {h,j,k,l}" = "bspc node -f {west,north,south,east}";
      "super + {Left,Up,Down,Right}" = "bspc node -f {west,north,south,east}";

      "super + shift + {h,j,k,l}" = "bspc node -s {west,north,south,east}";
      "super + shift + {Left,Up,Down,Right}" = "bspc node -s {west,north,south,east}";

      "super + ctrl + {h,j,k,l}" = "bspc node -z {left -20 0,right 20 0,bottom 0 20,top 0 -20}";
      "super + ctrl + {Left,Up,Down,Right}" = "bspc node -z {left -20 0,right 20 0,bottom 0 20,top 0 -20}";
    };
  };
}
