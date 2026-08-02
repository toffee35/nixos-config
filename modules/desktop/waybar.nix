{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.waybar;
  palette = config.modules.theme.palette;

  # Replaces waybar's own hyprland/language module, which cannot read this
  # keyboard: it looks for the last "(" in the event to find where the device
  # name ends, and this device is called ite-device(8910)-keyboard. The layout
  # name is then parsed out of the wrong place, and it only accidentally works
  # for layouts that carry a parenthesis themselves — "English (US)" resolves,
  # "Russian" does not and the label disappears.
  #
  # Here the device is matched exactly instead, and the layout is whatever
  # follows it, so parentheses and commas in either name are harmless.
  languageIndicator = pkgs.writeShellScriptBin "waybar-language" ''
    set -u

    label() {
      case "$1" in
        ${concatStringsSep "\n        " (mapAttrsToList
            (keymap: text: ''${escapeShellArg keymap}) printf '%s\n' ${escapeShellArg text} ;;'')
            cfg.languageLabels)}
        *) printf '%s\n' "$1" ;;
      esac
    }

    # The internal keyboard, resolved at runtime rather than hardcoded, so an
    # external keyboard cannot take the indicator over.
    keyboard=$(${pkgs.hyprland}/bin/hyprctl devices -j \
      | ${pkgs.jq}/bin/jq -r 'first(.keyboards[] | select(.main) | .name)')

    label "$(${pkgs.hyprland}/bin/hyprctl devices -j \
      | ${pkgs.jq}/bin/jq -r --arg kb "$keyboard" \
          'first(.keyboards[] | select(.name == $kb) | .active_keymap)')"

    ${pkgs.socat}/bin/socat -u \
      "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - \
      | while IFS= read -r event; do
          case "$event" in
            "activelayout>>$keyboard,"*) label "''${event#activelayout>>$keyboard,}" ;;
          esac
        done
  '';
in {
  options.modules.desktop.waybar = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Waybar status bar with system monitoring";
    };

    languageLabels = mkOption {
      type = types.attrsOf types.str;
      default = {
        "English (US)" = "EN";
        "Russian" = "RU";
      };
      description = ''
        Keyboard layout names as Hyprland reports them, mapped to what the bar
        should show. Anything not listed is displayed as-is.
      '';
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.modules.user.name} = {
      programs.waybar = {
        enable = true;
        settings.mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          spacing = 2;
          modules-left = [ "hyprland/workspaces" "hyprland/window" ];
          modules-center = [ "clock" ];
          modules-right = [ "pulseaudio" "custom/language" "network" "cpu" "memory" "temperature" "custom/gpu" "battery" "tray" ];

          # 1-5 are always drawn; 6-8 (bound in hyprland.nix) show up only while
          # they exist, i.e. hold a window or are the one you are looking at.
          "hyprland/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            persistent-workspaces = {
              "*" = [ 1 2 3 4 5 ];
            };
          };

          "hyprland/window" = {
            format = "{}";
            max-length = 50;
            separate-outputs = true;
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
            # Click flips between holding the charge limit and charging to
            # 100%, see modules/hardware/battery.nix
            on-click = "battery-charge-toggle";
            tooltip-format = "{capacity}% ({timeTo})\nClick to switch charge mode";
            format = "{icon} {capacity}%";
            format-charging = "⚡ {icon} {capacity}%";
            format-icons = [ "" "" "" "" "" ];
          };

          network = {
            interval = 2;
            format-wifi = "  {essid}  󰇚{bandwidthDownBytes}  󰕒{bandwidthUpBytes}";
            format-ethernet = "🔌 {ipaddr}/{cidr}  󰇚{bandwidthDownBytes}  󰕒{bandwidthUpBytes}";
            format-disconnected = "⚠️ Disconnected";
          };

          pulseaudio = {
            format = "🔊 {volume}%";
            format-muted = "🔇 Muted";
            on-click = "pavucontrol";
          };

          "custom/language" = {
            exec = "${languageIndicator}/bin/waybar-language";
            format = "🌐 {}";
            restart-interval = 5; # the script streams, restart it if it ever dies
            tooltip = false;
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
            color: ${palette.fg-bright};
            border-bottom: 2px solid ${palette.border};
          }
          #workspaces button {
            padding: 0 5px;
            background-color: transparent;
            color: ${palette.fg};
            border-bottom: 3px solid transparent;
          }
          #workspaces button.active {
            background-color: ${palette.border};
            color: ${palette.accent};
            border-bottom: 3px solid ${palette.accent};
          }
          #window {
            padding: 0 6px;
            margin: 0 2px;
          }
          #clock, #battery, #network, #pulseaudio, #cpu, #memory, #temperature, #custom-gpu, #tray, #custom-language {
            padding: 0 6px;
            margin: 0 2px;
          }
        '';
      };
    };
  };
}
