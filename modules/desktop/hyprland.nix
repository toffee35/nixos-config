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
      description = "Enable Hyprland desktop environment";
    };
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    home-manager.users.n = {
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

      # GTK Dark Theme Configuration
      gtk = {
        enable = true;
        theme = {
          name = "Orchis-Dark";
          package = pkgs.orchis-theme;
        };
        iconTheme = {
          name = "Tela-circle-dark";
          package = pkgs.tela-circle-icon-theme;
        };
      };

      # Qt Theme Configuration
      qt = {
        enable = true;
        platformTheme.name = "gtk3";
        style.name = "adwaita-dark";
      };

      # Cursor theme
      home.pointerCursor = {
        enable = true;
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
        size = 24;
        gtk.enable = true;
      };

      # Hyprland configuration
      wayland.windowManager.hyprland = {
        enable = true;
        settings = {
          exec-once = [
            "waybar"
            "hyprpaper"
            "mako"
          ];
          
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

      # Waybar Configuration
      programs.waybar = {
        enable = true;
        settings.mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "clock" ];
          modules-right = [ "pulseaudio" "network" "cpu" "memory" "temperature" "custom/gpu" "battery" "tray" ];

          "hyprland/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
          };

          cpu = {
            format = "  {usage}%";
            tooltip = true;
          };

          memory = {
            format = "  {used:0.1f}G/{total:0.1f}G";
          };

          temperature = {
            critical-threshold = 80;
            format = " {temperatureC}°C";
          };

          "custom/gpu" = {
            exec = "nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader,nounits 2>/dev/null | awk -F', ' '{print \"󰢮  \" $1 \"°C (\" $2 \"%%)\"}' || echo ''";
            interval = 5;
            format = "{}";
            tooltip = false;
          };

          clock = {
            format = "{:%H:%M | %d.%m.%Y}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };

          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = "⚡ {capacity}%";
            format-icons = [ "" "" "" "" "" ];
          };

          network = {
            format-wifi = "  {essid}";
            format-ethernet = "🔌 {ipaddr}/{cidr}";
            format-disconnected = "⚠️ Disconnected";
          };

          pulseaudio = {
            format = "🔊 {volume}%";
            format-muted = "🔇 Muted";
            on-click = "pavucontrol";
          };
        };

        style = ''
          * {
            font-family: "JetBrainsMono Nerd Font", sans-serif;
            font-size: 13px;
            border: none;
            border-radius: 0;
          }
          window#waybar {
            background-color: rgba(26, 27, 38, 0.9);
            color: #c0caf5;
            border-bottom: 2px solid #3b4261;
          }
          #workspaces button {
            padding: 0 8px;
            background-color: transparent;
            color: #a9b1d6;
            border-bottom: 3px solid transparent;
          }
          #workspaces button.active {
            background-color: #3b4261;
            color: #7aa2f7;
            border-bottom: 3px solid #7aa2f7;
          }
          #clock, #battery, #network, #pulseaudio, #cpu, #memory, #temperature, #custom-gpu, #tray {
            padding: 0 10px;
            margin: 0 5px;
          }
        '';
      };

      # Screen Lock configuration
      programs.hyprlock = {
        enable = true;
        settings = {
          general = {
            disable_loading_bar = true;
            grace = 0;
            hide_cursor = true;
            no_fade_in = false;
          };
          background = [
            {
              path = "screenshot";
              blur_passes = 3;
              blur_size = 8;
            }
          ];
          "input-field" = [
            {
              size = "200, 50";
              outline_thickness = 3;
              dots_size = 0.33;
              dots_spacing = 0.15;
              dots_center = true;
              outer_color = "rgb(122, 162, 247)";
              inner_color = "rgb(26, 27, 38)";
              font_color = "rgb(169, 177, 214)";
              fade_on_empty = false;
              placeholder_text = "<i>Enter Password...</i>";
              hide_input = false;
              position = "0, -20";
              halign = "center";
              valign = "center";
            }
          ];
        };
      };

      # Wofi Configuration
      programs.wofi = {
        enable = true;
        settings = {
          width = 500;
          height = 300;
          location = "center";
          show = "drun";
          prompt = "Search...";
          filter_rate = 100;
          allow_markup = true;
          no_actions = true;
          halign = "fill";
          orientation = "vertical";
          content_type = "modes";
        };
        style = ''
          window {
            margin: 0px;
            border: 2px solid #7aa2f7;
            background-color: #1a1b26;
            border-radius: 10px;
            font-family: "JetBrainsMono Nerd Font";
          }
          #input {
            margin: 5px;
            border: 1px solid #3b4261;
            color: #c0caf5;
            background-color: #24283b;
            border-radius: 5px;
          }
          #inner-box { margin: 5px; }
          #outer-box { margin: 5px; }
          #text { color: #c0caf5; }
          #entry:selected {
            background-color: #7aa2f7;
            border-radius: 5px;
          }
          #text:selected { color: #1a1b26; }
        '';
      };
    };

    # System-level fonts required for desktop rendering
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
  };
}
