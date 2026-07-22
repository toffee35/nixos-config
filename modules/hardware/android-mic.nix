{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.hardware.android-mic;
in {
  options.modules.hardware.android-mic = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable using an Android phone as a USB microphone via ADB (Audio Source)";
    };
  };

  config = mkIf cfg.enable {
    # Standard ADB udev rule: grants the active seat user access to the
    # device's ADB USB interface without needing root or a special group.
    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="ff", ATTR{bInterfaceSubClass}=="42", ATTR{bInterfaceProtocol}=="01", MODE="0666", TAG+="uaccess"
    '';

    home-manager.users.${config.modules.user.name} = {
      home.packages = with pkgs; [
        android-tools # provides adb
        audiosource   # forwards phone mic to PulseAudio/PipeWire over ADB
      ];
    };
  };
}
