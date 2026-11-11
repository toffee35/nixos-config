{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.apps.minecraft;
in
{
  options.modules.apps.minecraft = {
    enable = lib.mkEnableOption "PollyMC Continued Minecraft launcher" // {
      default = true;
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../pkgs/pollymc-continued.nix {
        withNvidiaOffload = config.modules.hardware.nvidia.enable;
      };
      description = "Minecraft launcher package.";
    };
  };
  config = lib.mkIf (cfg.enable && config.modules.apps.enable) {
    home-manager.users.${config.modules.user.name} = {
      home.packages = [ cfg.package ];
    };
  };
}
