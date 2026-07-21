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
      # Bind to all interfaces, but only actually reachable via wg0 below
      # (loopback stays implicitly allowed) — not exposed on the raw LAN.
      host = "0.0.0.0";
    };

    # Only the WireGuard interface may reach Ollama from the network.
    networking.firewall.interfaces.wg0.allowedTCPPorts = [ config.services.ollama.port ];
  };
}
