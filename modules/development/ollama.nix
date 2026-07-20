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
    };
  };
}
