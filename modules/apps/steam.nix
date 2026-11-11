{ config, lib, ... }:

let
  cfg = config.modules.apps.steam;
in {
  options.modules.apps.steam.enable = lib.mkEnableOption "Steam gaming client" // {
    default = true;
  };

  config = lib.mkIf (cfg.enable && config.modules.apps.enable) {
    # The NixOS module supplies the Steam runtime, graphics libraries and
    # controller udev rules, including the required 32-bit graphics support.
    programs.steam.enable = true;
  };
}
