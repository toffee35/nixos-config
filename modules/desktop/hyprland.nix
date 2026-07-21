{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.hyprland;
  palette = config.modules.theme.palette;

  # EASILY EDIT YOUR MONITOR RESOLUTION, REFRESH RATE, AND SCALE HERE:
  # Format: "name,resolution@refresh_rate,position,scale"
  # Default scale is 1 (no scaling). Set to e.g. 1.25 for fractional scaling.
  monitorSettings = ",preferred,auto,1";

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
    GEOM=$(${pkgs.slurp}/bin/slurp)
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
              "[workspace 4 silent] telegram-desktop"
              "[workspace 5 silent] blueman-manager"
              "[workspace 5 silent] pavucontrol"
              "[workspace 5 silent] kitty --class btop -e btop"
              "[workspace 5 silent] kitty --class kitty-empty"
            ]
            ++ optional config.modules.desktop.waybar.enable "waybar";

          monitor = monitorSettings;

          windowrule = [
            # Workspace 1: Zed
            "workspace 1, match:class dev.zed.Zed"

            # Workspace 2: Google Chrome
            "workspace 2 silent, match:class google-chrome"

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
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
            "col.active_border" = "rgba(${lib.removePrefix "#" palette.accent}ee) rgba(${lib.removePrefix "#" palette.accent2}ee) 45deg";
            "col.inactive_border" = "rgba(${lib.removePrefix "#" palette.muted}aa)";
            layout = "dwindle";
          };

          decoration = {
            rounding = 10;
            blur = {
              enabled = true;
              size = 3;
              passes = 1;
            };
          };

          animations = {
            enabled = true;
            bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
            animation = [
              "windows, 1, 5, myBezier"
              "windowsOut, 1, 5, default, popin 80%"
              "border, 1, 10, default"
              "fade, 1, 7, default"
              "workspaces, 1, 6, default"
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

            # Workspaces
            "$mod, 1, workspace, 1"
            "$mod, 2, workspace, 2"
            "$mod, 3, workspace, 3"
            "$mod, 4, workspace, 4"
            "$mod, 5, workspace, 5"

            # Move active window
            "$mod SHIFT, 1, movetoworkspace, 1"
            "$mod SHIFT, 2, movetoworkspace, 2"
            "$mod SHIFT, 3, movetoworkspace, 3"
            "$mod SHIFT, 4, movetoworkspace, 4"
            "$mod SHIFT, 5, movetoworkspace, 5"

            # Move active window silently to workspace (Ctrl + Win + number)
            "$mod CONTROL, 1, movetoworkspacesilent, 1"
            "$mod CONTROL, 2, movetoworkspacesilent, 2"
            "$mod CONTROL, 3, movetoworkspacesilent, 3"
            "$mod CONTROL, 4, movetoworkspacesilent, 4"
            "$mod CONTROL, 5, movetoworkspacesilent, 5"

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
