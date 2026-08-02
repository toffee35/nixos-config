{ config, pkgs, lib, inputs, ... }:

with lib;
let
  cfg = config.modules.hardware.quadcast-rgb;
in {
  imports = [ inputs.quadcastrgb.nixosModules.default ];

  options.modules.hardware.quadcast-rgb = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable QuadcastRGB lighting controller for HyperX Quadcast microphones";
    };
  };

  config = mkIf cfg.enable {
    # The upstream module installs the program and its udev rule; the rule has
    # to sort before systemd's 73-seat-late.rules, otherwise the uaccess tag is
    # set too late to ever become an ACL and the mic stays root-only.
    services.quadcastrgb = {
      enable = true;
      # This mic is a Quadcast 2S, which upstream only drives in solid mode.
      arguments = [ "solid" "ffffff" ];
    };
  };
}
