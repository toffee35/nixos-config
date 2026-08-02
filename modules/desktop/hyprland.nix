{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.hyprland;
  palette = config.modules.theme.palette;


  touchpad-toggle = pkgs.writeShellScriptBin "touchpad-toggle" ''
    DEVICE=$(${pkgs.hyprland}/bin/hyprctl devices -j | ${pkgs.jq}/bin/jq -r '.mice[] | select(.name | ascii_downcase | contains("touchpad")) | .name' | head -n 1)

    if [ -z "$DEVICE" ]; then
      ${pkgs.libnotify}/bin/notify-send -t 1500 -a "System" "Touchpad" "No touchpad device found"
      exit 1
    fi

    STATE_FILE="$XDG_RUNTIME_DIR/touchpad_state"
    if [ ! -f "$STATE_FILE" ]; then
      echo "enabled" > "$STATE_FILE"
    fi

    CURRENT_STATE=$(cat "$STATE_FILE")

    if [ "$CURRENT_STATE" = "enabled" ]; then
      ${pkgs.hyprland}/bin/hyprctl keyword "device[$DEVICE]:enabled" false
      echo "disabled" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send -t 1500 -a "System" "Touchpad" "Disabled"
    else
      ${pkgs.hyprland}/bin/hyprctl keyword "device[$DEVICE]:enabled" true
      echo "enabled" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send -t 1500 -a "System" "Touchpad" "Enabled"
    fi
  '';

  screenshot-full = pkgs.writeShellScriptBin "screenshot-full" ''
    mkdir -p "$HOME/Pictures"
    FILE="$HOME/Pictures/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
    ${pkgs.grim}/bin/grim "$FILE"
    ${pkgs.libnotify}/bin/notify-send -t 1500 -a "Screenshot" "Screenshot saved" "$FILE"
  '';

  screenshot-region = pkgs.writeShellScriptBin "screenshot-region" ''
    mkdir -p "$HOME/Pictures"

    # Freeze the screen (render-inactive, no zoom lens) so the selection isn't
    # made against a live/changing view, matching grimblast's --freeze behavior.
    ${pkgs.hyprpicker}/bin/hyprpicker -rz &
    PICKER_PID=$!
    sleep 0.2

    GEOM=$(${pkgs.slurp}/bin/slurp)

    kill "$PICKER_PID" 2>/dev/null

    [ -z "$GEOM" ] && exit 0
    FILE="$HOME/Pictures/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
    ${pkgs.grim}/bin/grim -g "$GEOM" "$FILE"
    ${pkgs.libnotify}/bin/notify-send -t 1500 -a "Screenshot" "Screenshot saved" "$FILE"
  '';
in {
  options.modules.desktop.hyprland = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Hyprland window manager";
    };

    monitors = mkOption {
      type = types.listOf types.str;
      default = [ ",preferred,auto,1" ];
      example = [ "eDP-1,2560x1600@165,0x0,1" "HDMI-A-1,preferred,auto,1" ];
      description = ''
        Hyprland monitor lines, "name,resolution@refresh,position,scale".
        The default catches every output with its preferred mode, unscaled.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_GFX_PROVIDER = "wayland";
    };

    home-manager.users.${config.modules.user.name} = {
      # Wayland utilities
      home.packages = with pkgs; [
        pavucontrol
        wl-clipboard
        libnotify
        mako
        fastfetch
        btop
        touchpad-toggle
        brightnessctl
        grim
        slurp
        hyprpicker
        screenshot-full
        screenshot-region
      ];

      # Hyprpaper Wallpaper Service
      services.hyprpaper = {
        enable = true;
        settings = {
          ipc = "on";
          preload = [ "${./tokyo-night.png}" ];
          wallpaper = [ ",${./tokyo-night.png}" ];
        };
      };

      # Hyprland configuration
      wayland.windowManager.hyprland = {
        enable = true;
        configType = "hyprlang";
        settings = {
          exec-once =
            [
              "hyprpaper"
              "mako"
              "[workspace 1] zeditor"
              "[workspace 2 silent] google-chrome-stable"
              "[workspace 3 silent] Discord"
              "[workspace 4 silent] Telegram"
              "[workspace 5 silent] blueman-manager"
              "[workspace 5 silent] pavucontrol"
              "[workspace 5 silent] kitty --class btop -e btop"
              "[workspace 5 silent] kitty --class kitty-empty"
            ]
            ++ optional config.modules.desktop.waybar.enable "waybar";

          monitor = cfg.monitors;

          windowrule = [
            # Workspace 1: Zed
            "workspace 1, match:class dev.zed.Zed"

            # Workspace 2: Google Chrome
            "workspace 2 silent, match:class google-chrome"

            # Workspace 3: Discord
            "workspace 3 silent, match:class discord"
            "workspace 3 silent, match:class Discord"

            # Workspace 4: Telegram
            "workspace 4 silent, match:class org.telegram.desktop"
            "workspace 4 silent, match:class telegram-desktop"
            "workspace 4 silent, match:class TelegramDesktop"

            # Workspace 5: Utilities and background terminals
            "workspace 5 silent, match:class blueman-manager"
            "workspace 5 silent, match:class pavucontrol"
            "workspace 5 silent, match:class btop"
            "workspace 5 silent, match:class kitty-empty"

            # Picture-in-Picture rules
            "float true, match:title Picture-in-Picture"
            "float true, match:title Picture in picture"
            "pin true, match:title Picture-in-Picture"
            "pin true, match:title Picture in picture"
            "keep_aspect_ratio true, match:title Picture-in-Picture"
            "keep_aspect_ratio true, match:title Picture in picture"
          ];

          input = {
            kb_layout = "us,ru";
            kb_options = "grp:alt_shift_toggle";
            follow_mouse = 1;
            touchpad.natural_scroll = true;
          };

          general = {
            gaps_in = 2;
            gaps_out = 4;
            border_size = 1;
            "col.active_border" = "rgba(ffffff66)";
            "col.inactive_border" = "rgba(ffffff00)";
            layout = "dwindle";
          };

          decoration = {
            rounding = 3;
            blur = {
              enabled = true;
              size = 3;
              passes = 1;
            };
          };

          animations = {
            enabled = true;
            # Durations are in deciseconds, so 3 = 300ms. Roughly half of the
            # Hyprland defaults: still visible, but out of the way before the
            # next keystroke lands. The curve no longer overshoots past 1.0
            # (was 1.05), since the bounce is what reads as "slow" even when
            # the duration itself is short.
            bezier = "myBezier, 0.05, 0.9, 0.1, 1.0";
            animation = [
              "windows, 1, 3, myBezier"
              "windowsOut, 1, 2, myBezier, popin 80%"
              "border, 1, 4, default"
              "fade, 1, 2, default"
              "workspaces, 1, 3, myBezier"
            ];
          };

          # Keybindings
          "$mod" = "SUPER";
          bind = [
            "$mod, Return, exec, kitty"
            "$mod, Q, killactive,"

            # Application launcher (Wofi)
            "$mod, R, exec, wofi --show drun"
            "$mod, D, exec, wofi --show drun"
            "$mod, SPACE, exec, wofi --show drun"

            # Screen lock (Win + L)
            "$mod, L, exec, hyprlock"

            # Pin focused window to all workspaces (Win + P)
            "$mod, P, pin"

            # Toggle hiding the focused window from screen shares/recordings
            # (native Hyprland "no_screen_share" rule — window stays visible
            # to you, screencopy consumers like OBS/Discord/browser share see
            # a black box in its place instead)
            "$mod SHIFT, H, setprop, activewindow no_screen_share toggle"

            # Touchpad toggle (Fn + F10 maps to XF86TouchpadToggle)
            ", XF86TouchpadToggle, exec, touchpad-toggle"

            # Screenshots (Print Screen key, labeled "Druck" on some layouts)
            ", Print, exec, screenshot-full"
            "$mod, Print, exec, screenshot-region"
            "$mod, M, exit,"
            "$mod, V, togglefloating,"
            "$mod, F, fullscreen,"

            # Focus
            "$mod, left, movefocus, l"
            "$mod, right, movefocus, r"
            "$mod, up, movefocus, u"
            "$mod, down, movefocus, d"

            # Workspaces. 1-5 are always shown in the bar (persistent-workspaces
            # in waybar.nix); 6-8 only appear there once they hold a window.
            "$mod, 1, workspace, 1"
            "$mod, 2, workspace, 2"
            "$mod, 3, workspace, 3"
            "$mod, 4, workspace, 4"
            "$mod, 5, workspace, 5"
            "$mod, 6, workspace, 6"
            "$mod, 7, workspace, 7"
            "$mod, 8, workspace, 8"

            # Move active window to workspace without following it there
            "$mod SHIFT, 1, movetoworkspacesilent, 1"
            "$mod SHIFT, 2, movetoworkspacesilent, 2"
            "$mod SHIFT, 3, movetoworkspacesilent, 3"
            "$mod SHIFT, 4, movetoworkspacesilent, 4"
            "$mod SHIFT, 5, movetoworkspacesilent, 5"
            "$mod SHIFT, 6, movetoworkspacesilent, 6"
            "$mod SHIFT, 7, movetoworkspacesilent, 7"
            "$mod SHIFT, 8, movetoworkspacesilent, 8"

            # Move active window silently to workspace (Ctrl + Win + number)
            "$mod CONTROL, 1, movetoworkspacesilent, 1"
            "$mod CONTROL, 2, movetoworkspacesilent, 2"
            "$mod CONTROL, 3, movetoworkspacesilent, 3"
            "$mod CONTROL, 4, movetoworkspacesilent, 4"
            "$mod CONTROL, 5, movetoworkspacesilent, 5"
            "$mod CONTROL, 6, movetoworkspacesilent, 6"
            "$mod CONTROL, 7, movetoworkspacesilent, 7"
            "$mod CONTROL, 8, movetoworkspacesilent, 8"

            # Move active window inside the workspace (Shift + Win + arrow)
            "$mod SHIFT, left, movewindow, l"
            "$mod SHIFT, right, movewindow, r"
            "$mod SHIFT, up, movewindow, u"
            "$mod SHIFT, down, movewindow, d"
          ];

          # Repeatable media and brightness keys (work when screen is locked)
          bindle = [
            # Fn+F2: Volume down 5%
            ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            # Fn+F3: Volume up 5% (capped at 100%)
            ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
            # Fn+F5: Brightness down 5%
            ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
            # Fn+F6: Brightness up 5%
            ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
          ];

          # Locked media keys (mute audio/mic, work when screen is locked)
          bindl = [
            # Fn+F1: Mute audio AND microphone
            ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
            # Fn+F4: Mute microphone only
            ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ];

          # Resize windows (repeatable Ctrl + Win + arrow)
          binde = [
            "$mod CONTROL, left, resizeactive, -20 0"
            "$mod CONTROL, right, resizeactive, 20 0"
            "$mod CONTROL, up, resizeactive, 0 -20"
            "$mod CONTROL, down, resizeactive, 0 20"
          ];

          # Mouse bindings (Win + mouse left/right click)
          bindm = [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];
        };
      };
    };
  };
}
