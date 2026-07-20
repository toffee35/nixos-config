{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.kitty;
in {
  options.modules.desktop.kitty = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Kitty terminal emulator with Tokyo Night theme";
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.n = {
      programs.kitty = {
        enable = true;
        font = {
          name = "JetBrainsMono Nerd Font";
          size = 11;
        };
        settings = {
          scrollback_lines = 10000;
          enable_audio_bell = false;
          update_check_interval = 0;
          
          # Tokyo Night Dark color scheme
          background = "#1a1b26";
          foreground = "#a9b1d6";
          selection_background = "#283457";
          selection_foreground = "#c0caf5";
          url_color = "#73daca";
          cursor = "#c0caf5";
          
          # Tab bar
          tab_bar_style = "powerline";
          active_tab_background = "#7aa2f7";
          active_tab_foreground = "#1f2335";
          inactive_tab_background = "#353749";
          inactive_tab_foreground = "#a9b1d6";

          # 16 Colors
          # black
          color0 = "#414868";
          color8 = "#414868";
          # red
          color1 = "#f7768e";
          color9 = "#f7768e";
          # green
          color2 = "#9ece6a";
          color10 = "#9ece6a";
          # yellow
          color3 = "#e0af68";
          color11 = "#e0af68";
          # blue
          color4 = "#7aa2f7";
          color12 = "#7aa2f7";
          # magenta
          color5 = "#bb9af7";
          color13 = "#bb9af7";
          # cyan
          color6 = "#7db9f5";
          color14 = "#7db9f5";
          # white
          color7 = "#a9b1d6";
          color15 = "#c0caf5";
        };
      };
    };
  };
}
