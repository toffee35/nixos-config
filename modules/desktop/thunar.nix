{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.thunar;
in {
  options.modules.desktop.thunar = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Thunar file manager";
    };
  };

  config = mkIf cfg.enable {
    programs.thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    services.gvfs.enable = true;
    services.tumbler.enable = true;

    home-manager.users.n = {
      # Bind shortcut only if Hyprland is also enabled
      wayland.windowManager.hyprland.settings.bind = mkIf config.modules.desktop.hyprland.enable [
        "$mod, E, exec, thunar"
      ];
    };
  };
}
