{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.sddm;
in {
  options.modules.desktop.sddm = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable SDDM display manager with astronaut theme";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.sddm-astronaut.override {
        # Show the actual login name (e.g. "n") instead of the account's GECOS
        # description ("NixOS User"), which is what UseRealName displays by default.
        themeConfig = {
          UseRealName = "false";
        };
      })
    ];

    services.xserver.enable = true;

    services.displayManager.defaultSession = "hyprland";

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "sddm-astronaut-theme";
      extraPackages = [
        (pkgs.sddm-astronaut.override {
          themeConfig = {
            UseRealName = "false";
          };
        })
      ];
      settings = {
        Users = {
          RememberLastUser = true;
          RememberLastSession = true;
        };
        Theme = {
          Current = "sddm-astronaut-theme";
        };
      };
    };
  };
}
