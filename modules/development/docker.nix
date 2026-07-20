{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.development.docker;
in {
  options.modules.development.docker = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Docker and configure firewall for local access";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;
    
    # Allow user to access docker without sudo
    users.users.${config.modules.user.name}.extraGroups = [ "docker" ];

    # Declarative Docker Containers
    virtualisation.oci-containers = {
      backend = "docker";
      containers = {
        portainer = {
          image = "portainer/portainer-ce:latest";
          ports = [ "9000:9000" ];
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            "portainer_data:/data"
          ];
        };
        transmission = {
          image = "linuxserver/transmission:latest";
          ports = [
            "9091:9091"
            "51413:51413"
            "51413:51413/udp"
          ];
          environment = {
            PUID = "1000";
            PGID = "100";
            TZ = "Europe/Belgrade";
          };
          volumes = [
            "/home/${config.modules.user.name}/Downloads/transmission/config:/config"
            "/home/${config.modules.user.name}/Downloads:/downloads"
            "/home/${config.modules.user.name}/Downloads/transmission/watch:/watch"
          ];
        };
      };
    };
  };
}
