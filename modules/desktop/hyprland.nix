{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.hyprland;

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
      ];

      # Hyprpaper Wallpaper Service
      services.hyprpaper = {
        enable = true;
        settings = {
          ipc = "on";
        };
      };

      # Hyprland configuration
      wayland.windowManager.hyprland = {
        enable = true;
        settings = {
          exec-once =
            [ "hyprpaper" "mako" ]
            ++ optional config.modules.desktop.waybar.enable "waybar";

          monitor = ",2560x1600@165,auto,1.25";

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
            "col.active_border" = "rgba(7aa2f7ee) rgba(bb9af7ee) 45deg";
            "col.inactive_border" = "rgba(414868aa)";
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

            # Screen lock (Win + L)
            "$mod, L, exec, hyprlock"

            # Touchpad toggle (Fn + F10 maps to XF86TouchpadToggle)
            ", XF86TouchpadToggle, exec, touchpad-toggle"
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
        };
      };
    };
  };
}
