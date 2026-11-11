{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.easyeffects;
in {
  options.modules.desktop.easyeffects = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable EasyEffects audio effects for PipeWire";
    };

    excludedOutputDevices = mkOption {
      type = types.listOf types.str;
      default = [ "alsa_output.pci-0000_05_00.6.analog-stereo" ];
      description = "Output devices that bypass automatic EasyEffects processing.";
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.modules.user.name} = { config, ... }: let
      settingsFile = "${config.xdg.configHome}/easyeffects/db/easyeffectsrc";
      configureOutputs = pkgs.writeShellScript "easyeffects-output-routing" ''
        set -eu
        ${pkgs.coreutils}/bin/mkdir -p ${escapeShellArg (builtins.dirOf settingsFile)}
        ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
          --file ${escapeShellArg settingsFile} \
          --group EffectsPipelines --key outputSinkBlocklist \
          ${escapeShellArg (concatStringsSep "," cfg.excludedOutputDevices)}
      '';
    in {
      # Keep presets writable in the GUI. Only enforce output routing before
      # startup: the built-in speakers crackled through the output pipeline,
      # even with its filter bypassed, while direct playback was clean.
      services.easyeffects.enable = true;
      systemd.user.services.easyeffects.Service.ExecStartPre = [ "${configureOutputs}" ];
    };
  };
}
