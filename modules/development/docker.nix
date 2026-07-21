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
          # Bound to loopback + the wg0 tunnel address only, not "0.0.0.0":
          # Docker's own iptables rules bypass the NixOS firewall for published
          # ports (verified via `ss -tlnp` showing it reachable on all
          # interfaces despite the firewall being active), so binding to a
          # specific IP is what actually restricts reachability here — the
          # admin UI is reachable from the laptop itself and over the
          # WireGuard tunnel, but not from the raw LAN.
          ports = [ "127.0.0.1:9000:9000" "10.100.0.1:9000:9000" ];
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            "portainer_data:/data"
          ];
        };
        transmission = {
          image = "linuxserver/transmission:latest";
          ports = [
            "127.0.0.1:9091:9091"
            "10.100.0.1:9091:9091"
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

    # Both containers bind to the wg0 address; make sure the tunnel is up
    # first, otherwise those specific port bindings fail at container start.
    systemd.services."docker-portainer" = {
      after = [ "wireguard-wg0.service" ];
      requires = [ "wireguard-wg0.service" ];
    };
    systemd.services."docker-transmission" = {
      after = [ "wireguard-wg0.service" ];
      requires = [ "wireguard-wg0.service" ];
    };
  };
}
