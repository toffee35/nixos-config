{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.wofi;
  palette = config.modules.theme.palette;
in {
  options.modules.desktop.wofi = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Wofi application launcher";
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.modules.user.name} = {
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
            border: 2px solid ${palette.accent};
            background-color: ${palette.bg};
            border-radius: 10px;
            font-family: "JetBrainsMono Nerd Font";
          }
          #input {
            margin: 5px;
            border: 1px solid ${palette.border};
            color: ${palette.fg-bright};
            background-color: ${palette.surface};
            border-radius: 5px;
          }
          #inner-box { margin: 5px; }
          #outer-box { margin: 5px; }
          #text { color: ${palette.fg-bright}; }
          #entry:selected {
            background-color: ${palette.accent};
            border-radius: 5px;
          }
          #text:selected { color: ${palette.bg}; }
        '';
      };
    };
  };
}
