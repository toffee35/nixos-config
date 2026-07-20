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
    users.users.n.extraGroups = [ "docker" ];

    # Open TCP/UDP ports 1024-65535 to easily access any docker container / dev server from local network
    networking.firewall.allowedTCPPortRanges = [ { from = 1024; to = 65535; } ];
    networking.firewall.allowedUDPPortRanges = [ { from = 1024; to = 65535; } ];
  };
}
