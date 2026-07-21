{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.hardware.boot;
in {
  options.modules.hardware.boot = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable standard GRUB EFI bootloader configuration";
    };
  };

  config = mkIf cfg.enable {
    # Bootloader (Using GRUB as requested)
    boot.loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      configurationLimit = 5;
    };
    boot.loader.timeout = 2;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
