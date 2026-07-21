{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.development.ollama;
in {
  options.modules.development.ollama = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Ollama local AI model inference with CUDA acceleration";
    };
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      # Bind to all interfaces; reachable via wg0 (trusted interface, see
      # modules/hardware/wireguard.nix) and loopback, not the raw LAN.
      host = "0.0.0.0";
    };
  };
}
