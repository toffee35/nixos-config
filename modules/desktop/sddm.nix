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
      pkgs.sddm-astronaut
    ];

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "sddm-astronaut-theme";
      extraPackages = [ pkgs.sddm-astronaut ];
    };
  };
}
