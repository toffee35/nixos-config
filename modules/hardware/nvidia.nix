{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.hardware.nvidia;
in {
  options.modules.hardware.nvidia = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Nvidia proprietary driver with Wayland/Hyprland support";
    };
  };

  config = mkIf cfg.enable {
    # Enable hardware graphics acceleration
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Load Nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management (can cause sleep issues if enabled, keeping false for stability)
      powerManagement.enable = false;
      powerManagement.finegrained = false;

      # Use the proprietary closed source driver (stable and robust for laptop RTX 3060)
      open = false;

      # Enable Nvidia settings menu
      nvidiaSettings = true;

      # Use the stable driver release package
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Environment variables for Nvidia on Wayland / Hyprland
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
  };
}
