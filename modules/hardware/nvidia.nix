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

      # Required for proper suspend/resume: installs nvidia-suspend/resume/hibernate
      # systemd units that save/restore VRAM and modeset state. Without this, resuming
      # from lid-close sleep hits "Failed to apply atomic modeset" and crashes the
      # Hyprland session (seen in journalctl as nv_drm_atomic_commit errors).
      powerManagement.enable = true;
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
