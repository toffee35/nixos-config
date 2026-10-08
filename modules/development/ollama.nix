{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.development.ollama;
in {
  options.modules.development.ollama = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Ollama with the Open WebUI front-end, in containers, on the GPU";
    };
  };

  config = mkIf cfg.enable {
    # Versions are pinned rather than :latest, so an unrelated `docker pull`
    # never swaps the runtime under a working setup. Bump them deliberately.
    #
    # The GPU is shared, not handed over: CDI exposes the device nodes and the
    # host driver to the container, and the host keeps using the card for its
    # own CUDA at the same time.
    hardware.nvidia-container-toolkit.enable = true;

    virtualisation.oci-containers.containers = {
      ollama = {
        image = "ollama/ollama:0.34.4";

        # Loopback plus the WireGuard address, as with the other containers in
        # ./docker.nix: Docker's published ports bypass the NixOS firewall, so
        # the bind address is what keeps this off the LAN.
        ports = [
          "127.0.0.1:11434:11434"
          "10.100.0.1:11434:11434"
        ];

        # Models live in a Docker volume, not under /home: they are large and
        # managed entirely through ollama itself (`ollama pull`).
        volumes = [ "ollama_data:/root/.ollama" ];

        extraOptions = [ "--device=nvidia.com/gpu=all" ];

        # Shared network so the front-end can reach this by name. Created by
        # the unit below; the published ports above stay for host access.
        networks = [ "llm" ];
      };

      open-webui = {
        image = "ghcr.io/open-webui/open-webui:v0.11.4";

        ports = [
          "127.0.0.1:3000:8080"
          "10.100.0.1:3000:8080"
        ];

        volumes = [ "open_webui_data:/app/backend/data" ];

        environment = {
          # Reached over the shared network by container name. host-gateway was
          # tried first and timed out: it resolves to the docker bridge address
          # (172.17.0.1), and ollama publishes only on loopback and the
          # WireGuard address, so nothing was listening there.
          OLLAMA_BASE_URL = "http://ollama:11434";
          # Single-user laptop: skip the login wall.
          WEBUI_AUTH = "False";

          # Open WebUI copies most settings into its own database on first
          # start and ignores the environment from then on — which is how it
          # kept pointing at the old, unreachable host.docker.internal URL
          # after the module had already been fixed. This keeps the
          # environment authoritative on every start instead.
          ENABLE_PERSISTENT_CONFIG = "False";
        };

        networks = [ "llm" ];

        dependsOn = [ "ollama" ];
      };
    };

    # Both bind to the wg0 address, so the tunnel has to exist first; ollama
    # also needs the CDI spec that the toolkit writes on boot.
    systemd.services.docker-ollama = {
      after = [ "wireguard-wg0.service" "nvidia-container-toolkit-cdi-generator.service" ];
      requires = [ "wireguard-wg0.service" ];
    };
    systemd.services.docker-open-webui = {
      after = [ "wireguard-wg0.service" ];
      requires = [ "wireguard-wg0.service" ];
    };

    # The `networks` option above only joins the network; something has to
    # create it. Idempotent, so it is safe on every boot.
    systemd.services.docker-network-llm = {
      description = "Create the llm Docker network";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ config.virtualisation.docker.package ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = "docker network inspect llm > /dev/null 2>&1 || docker network create llm";
    };
  };
}
