{ config, lib, ... }:

with lib;
let
  cfg = config.modules.theme;
in {
  options.modules.theme = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable centralized Tokyo Night color palette";
    };

    palette = {
      bg = mkOption { type = types.str; default = "#1a1b26"; description = "Background"; };
      bg-dark = mkOption { type = types.str; default = "#1f2335"; description = "Dark background"; };
      bg-highlight = mkOption { type = types.str; default = "#292e42"; description = "Background highlight"; };
      surface = mkOption { type = types.str; default = "#24283b"; description = "Surface"; };
      fg = mkOption { type = types.str; default = "#a9b1d6"; description = "Foreground"; };
      fg-bright = mkOption { type = types.str; default = "#c0caf5"; description = "Bright foreground"; };
      accent = mkOption { type = types.str; default = "#7aa2f7"; description = "Primary accent (blue)"; };
      accent2 = mkOption { type = types.str; default = "#bb9af7"; description = "Secondary accent (magenta)"; };
      border = mkOption { type = types.str; default = "#3b4261"; description = "Border color"; };
      muted = mkOption { type = types.str; default = "#414868"; description = "Muted/disabled"; };
      selection-bg = mkOption { type = types.str; default = "#283457"; description = "Selection background"; };
      red = mkOption { type = types.str; default = "#f7768e"; description = "Red"; };
      green = mkOption { type = types.str; default = "#9ece6a"; description = "Green"; };
      yellow = mkOption { type = types.str; default = "#e0af68"; description = "Yellow"; };
      cyan = mkOption { type = types.str; default = "#7dcfff"; description = "Cyan"; };
      cyan-alt = mkOption { type = types.str; default = "#7db9f5"; description = "Cyan alternative"; };
      teal = mkOption { type = types.str; default = "#73daca"; description = "Teal"; };
      inactive-tab-bg = mkOption { type = types.str; default = "#353749"; description = "Inactive tab background"; };
    };
  };
}
