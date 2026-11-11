{ config, lib, pkgs, ... }:

let
  cfg = config.modules.development.ollama;
  enabled = cfg.enable && config.modules.development.docker.enable;
  network = "ollama-webui";
in {
  options.modules.development.ollama = {
    enable = lib.mkEnableOption "Ollama and Open WebUI in Docker" // { default = true; };
    ollamaImage = lib.mkOption {
      type = lib.types.str;
      default = "ollama/ollama@sha256:5d3a2f25f9825628daba94dc0b1d421c7d57d6c03ae5faa9ba050e058bab8241";
      description = "Ollama image, optionally pinned to a version or digest.";
    };
    webuiImage = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/open-webui/open-webui@sha256:4e1dd31538187a4c5749b30880dbc8ae745b2827cf9016cbfd691b431199b230";
      description = "Open WebUI image, optionally pinned to a version or digest.";
    };
  };

  config = lib.mkIf enabled {
    # Native CDI supplies both device nodes and the host driver libraries.
    hardware.nvidia-container-toolkit.enable = true;

    virtualisation.oci-containers = {
      backend = "docker";
      containers = {
        ollama = {
          image = cfg.ollamaImage;
          networks = [ network ];
          devices = [ "nvidia.com/gpu=all" ];
          ports = [ "127.0.0.1:11434:11434" ];
          volumes = [ "ollama:/root/.ollama" ];
          environment = {
            OLLAMA_HOST = "0.0.0.0:11434";
            # Limit concurrent VRAM use on the laptop's 6 GiB GPU.
            OLLAMA_MAX_LOADED_MODELS = "1";
            OLLAMA_NUM_PARALLEL = "1";
          };
        };
        open-webui = {
          image = cfg.webuiImage;
          dependsOn = [ "ollama" ];
          networks = [ network ];
          ports = [ "127.0.0.1:3000:8080" ];
          volumes = [ "open-webui:/app/backend/data" ];
          environment.OLLAMA_BASE_URL = "http://ollama:11434";
          environmentFiles = [ config.modules.secrets.paths.webui ];
        };
      };
    };

    systemd.services.ollama-network = {
      description = "Create the Docker network for Ollama and Open WebUI";
      requires = [ "docker.service" ];
      after = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ config.virtualisation.docker.package ];
      script = ''
        docker network inspect ${network} >/dev/null 2>&1 || docker network create ${network}
      '';
    };

    systemd.services.docker-ollama = {
      requires = [ "ollama-network.service" "nvidia-container-toolkit-cdi-generator.service" ];
      after = [ "ollama-network.service" "nvidia-container-toolkit-cdi-generator.service" ];
    };
    systemd.services.docker-open-webui = {
      requires = [ "ollama-network.service" ];
      after = [ "ollama-network.service" ];
      serviceConfig = {
        StateDirectory = "open-webui";
        StateDirectoryMode = "0700";
        UMask = "0077";
      };
      # Persist the signing key across container recreation; never put it in
      # the Nix store. Docker reads this file at run time, after preStart.
      preStart = lib.mkBefore ''
        if [ ! -s /var/lib/open-webui/secret.env ]; then
          key=$(${pkgs.openssl}/bin/openssl rand -hex 32)
          printf 'WEBUI_SECRET_KEY=%s\n' "$key" > /var/lib/open-webui/secret.env
        fi
      '';
    };
  };
}
