{ config, pkgs, lib, inputs, ... }:

with lib;
let
  cfg = config.modules.apps.antigravity;
in {
  options.modules.apps.antigravity = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Google Antigravity apps (orchestrator, ide, cli)";
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.modules.user.name} = {
      home.packages = [
        inputs.antigravity.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-no-fhs
        inputs.antigravity.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-ide-no-fhs
        inputs.antigravity.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli
      ];
    };
  };
}
