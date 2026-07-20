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
    home-manager.users.n = {
      home.packages = [
        inputs.antigravity.packages.${pkgs.system}.google-antigravity
        inputs.antigravity.packages.${pkgs.system}.google-antigravity-ide
        inputs.antigravity.packages.${pkgs.system}.google-antigravity-cli
      ];
    };
  };
}
