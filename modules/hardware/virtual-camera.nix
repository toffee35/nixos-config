{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.hardware.virtualCamera;
in {
  options.modules.hardware.virtualCamera = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable v4l2loopback so OBS can expose a virtual camera";
    };
  };

  config = mkIf cfg.enable {
    # OBS writes into a loopback device and everything else sees an ordinary
    # webcam. The module is built against the running kernel, so it can be
    # modprobe'd straight after a switch — no reboot needed unless the kernel
    # itself changed.
    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" ];

    # exclusive_caps=1 is what makes Chrome, Discord and Zoom accept the device:
    # without it they skip anything that also advertises output capability.
    # card_label is the name those apps show in their camera picker.
    boot.extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=0 card_label="OBS Virtual Camera" exclusive_caps=1
    '';
  };
}
