{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.hyprlock;
  palette = config.modules.theme.palette;
in {
  options.modules.desktop.hyprlock = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Hyprlock screen locker";
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.modules.user.name} = {
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
              outer_color = "rgb(${lib.removePrefix "#" palette.accent})";
              inner_color = "rgb(${lib.removePrefix "#" palette.bg})";
              font_color = "rgb(${lib.removePrefix "#" palette.fg})";
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
    };
  };
}
