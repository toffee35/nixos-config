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
    home-manager.users.${config.modules.user.name} = {
      programs.kitty = let
        palette = config.modules.theme.palette;
      in {
        enable = true;
        font = {
          name = "JetBrainsMono Nerd Font";
          size = 11;
        };
        settings = {
          scrollback_lines = 10000;
          enable_audio_bell = false;
          update_check_interval = 0;
          confirm_os_window_close = 0;

          # Tokyo Night Dark color scheme (from modules/theme.nix)
          background = palette.bg;
          foreground = palette.fg;
          selection_background = palette.selection-bg;
          selection_foreground = palette.fg-bright;
          url_color = palette.teal;
          cursor = palette.fg-bright;

          # Tab bar
          tab_bar_style = "powerline";
          active_tab_background = palette.accent;
          active_tab_foreground = palette.bg-dark;
          inactive_tab_background = palette.inactive-tab-bg;
          inactive_tab_foreground = palette.fg;

          # 16 Colors
          # black
          color0 = palette.muted;
          color8 = palette.muted;
          # red
          color1 = palette.red;
          color9 = palette.red;
          # green
          color2 = palette.green;
          color10 = palette.green;
          # yellow
          color3 = palette.yellow;
          color11 = palette.yellow;
          # blue
          color4 = palette.accent;
          color12 = palette.accent;
          # magenta
          color5 = palette.accent2;
          color13 = palette.accent2;
          # cyan
          color6 = palette.cyan-alt;
          color14 = palette.cyan-alt;
          # white
          color7 = palette.fg;
          color15 = palette.fg-bright;
        };
      };
    };
  };
}
