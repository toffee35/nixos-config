{ config, pkgs, lib, inputs, ... }:

with lib;
let
  cfg = config.modules.hardware.legion-rgb;
in {
  options.modules.hardware.legion-rgb = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable 4JX L5P-Keyboard-RGB backlight controller and udev rules";
    };
  };

  config = mkIf cfg.enable {
    # Install the L5P-Keyboard-RGB utility from flake inputs
    environment.systemPackages = [
      inputs.l5p-keyboard-rgb.packages.${pkgs.system}.default
    ];

    # Add udev rules for the 2021 Lenovo Legion 5 Pro (product ID c965)
    # This allows non-root users to write to the keyboard controller
    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="048d", ATTR{idProduct}=="c965", MODE="0666"
    '';
  };
}
