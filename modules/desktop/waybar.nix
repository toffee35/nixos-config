{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.waybar;
  palette = config.modules.theme.palette;
in {
  options.modules.desktop.waybar = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Waybar status bar with system monitoring";
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
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "clock" ];
          modules-right = [ "pulseaudio" "hyprland/language" "network" "cpu" "memory" "temperature" "custom/gpu" "battery" "tray" ];

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
            format-charging = "⚡ {icon} {capacity}%";
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

          "hyprland/language" = {
            format = "🌐 {}";
            format-en = "EN";
            format-ru = "RU";
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
            padding: 0 8px;
            background-color: transparent;
            color: ${palette.fg};
            border-bottom: 3px solid transparent;
          }
          #workspaces button.active {
            background-color: ${palette.border};
            color: ${palette.accent};
            border-bottom: 3px solid ${palette.accent};
          }
          #clock, #battery, #network, #pulseaudio, #cpu, #memory, #temperature, #custom-gpu, #tray, #language {
            padding: 0 10px;
            margin: 0 5px;
          }
        '';
      };
    };
  };
}
