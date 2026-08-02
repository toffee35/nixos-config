{ config, pkgs, lib, inputs, ... }:

with lib;
let
  cfg = config.modules.hardware.legion-rgb;

  # NOT services.udev.extraRules: that lands in 99-local.rules, while systemd's
  # 73-seat-late.rules is what turns TAG=="uaccess" into an actual ACL. A tag
  # added at 99 is never seen by that match, so the keyboard stayed root-only.
  # Same reasoning as in quadcast-rgb.nix.
  udevRules = pkgs.writeTextFile {
    name = "l5p-keyboard-rgb-udev-rules";
    destination = "/etc/udev/rules.d/60-l5p-keyboard-rgb.rules";
    text = ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="048d", ATTR{idProduct}=="c965", TAG+="uaccess"
    '';
  };
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
      inputs.l5p-keyboard-rgb.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    services.udev.packages = [ udevRules ];
  };
}
