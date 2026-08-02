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
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.modules.user.name} = {
      # Only `enable` on purpose. The module also takes declarative presets,
      # but those land in the store read-only and the GUI can then no longer
      # edit them — so presets stay where they are made, in ~/.config/easyeffects.
      # This just installs the program and runs it in the background, so the
      # effects apply without keeping the window open.
      services.easyeffects.enable = true;
    };
  };
}
