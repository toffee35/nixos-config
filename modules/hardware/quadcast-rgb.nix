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
      # libusb starts an event thread before the program daemonizes. Forking
      # afterwards can leave the child waiting forever on an inherited mutex.
      # Keep the process in the foreground under systemd instead.
      package = (inputs.quadcastrgb.packages.${pkgs.stdenv.hostPlatform.system}.quadcastrgb).overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace modules/devio.c \
            --replace-fail '    daemonize(verbose);' \
              '    if (!getenv("QUADCASTRGB_FOREGROUND")) daemonize(verbose);'
        '';
      });
      # This mic is a Quadcast 2S, which upstream only drives in solid mode.
      arguments = [ "solid" "ffffff" ];
    };

    systemd.user.services.quadcastrgb = {
      environment.QUADCASTRGB_FOREGROUND = "1";
      serviceConfig.Type = lib.mkForce "simple";
    };

    # Every mute toggle makes the mic reset its HID interfaces, which kills the
    # running program; the firmware then shows its own rainbow cycle until the
    # service is back. Upstream waits 2 s before restarting, which is exactly
    # the slow rainbow-to-white fade seen after every unmute. 200 ms makes it
    # imperceptible while still keeping the retry loop cheap when no mic is
    # attached (the program exits at once then, and StartLimitIntervalSec is 0).
    systemd.user.services.quadcastrgb.serviceConfig.RestartSec = lib.mkForce "200ms";
  };
}
