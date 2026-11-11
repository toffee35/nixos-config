{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.hardware.nvidia;
  toolsPatchelf = pkgs.callPackage ../../pkgs/nvidia-patchelf.nix { };
  driver = config.boot.kernelPackages.nvidiaPackages.stable.overrideAttrs (old: {
    postInstall = (if old.postInstall == null then "" else old.postInstall) + ''
      for original in "$bin"/origBin/*; do
        [ -f "$original" ] || continue
        target="$bin/bin/$(basename "$original")"
        cp "$original" "$target"
        chmod u+w "$target"
        ${toolsPatchelf}/bin/patchelf \
          --set-interpreter "$(cat "$NIX_CC/nix-support/dynamic-linker")" \
          --set-rpath "$out/lib:$libPath" "$target"
      done
    '';
  });
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
      package = driver;
    };

    # These force GBM, GLX and VA-API onto the Nvidia card, which is right only
    # when Nvidia is the sole GPU — the "ddg" specialisation from nixos-hardware,
    # booted with Dual-Direct GFX enabled in the BIOS. In the default hybrid
    # mode the internal panel hangs off the AMD iGPU; exported globally, these
    # would drag the compositor, browsers and Discord back onto the dGPU and its
    # 6 GB, which is exactly what hybrid mode is for avoiding. Apps that need
    # Nvidia there go through `nvidia-offload`.
    specialisation.ddg.configuration.environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
  };
}
