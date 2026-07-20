{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.hypridle;
in {
  options.modules.desktop.hypridle = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Hypridle idle daemon to auto-lock the screen";
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.modules.user.name} = {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };
          listener = [
            {
              timeout = 300; # 5 minutes
              on-timeout = "hyprlock";
            }
            {
              timeout = 330; # 5.5 minutes
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };
    };
  };
}
