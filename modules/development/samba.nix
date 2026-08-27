{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.development.samba;
  user = config.modules.user.name;
in {
  options.modules.development.samba = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Share the user's home directory over SMB, reachable through the WireGuard tunnel";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.samba = {
      image = "ghcr.io/servercontainers/samba:latest";

      # Bound to the WireGuard address only — same reasoning as the other
      # containers in ./docker.nix: Docker's published ports bypass the NixOS
      # firewall, so the bind address is the actual restriction. Port 445 must
      # never face the raw LAN, let alone a cafe network.
      ports = [ "10.100.0.1:445:445" ];

      volumes = [ "/home/${user}:/shares/home" ];

      environment = {
        TZ = "Europe/Belgrade";

        # Map the SMB account onto the real user so files keep their ownership
        # instead of landing as root.
        "UID_${user}" = "1000";
        "GID_${user}" = "100";

        # The share itself. `valid users` keeps it off guest access.
        "SAMBA_VOLUME_CONFIG_home" = ''
          [home]
          path = /shares/home
          valid users = ${user}
          guest ok = no
          read only = no
          browseable = yes
        '';

        # No NetBIOS/WSD discovery: the tunnel has exactly one client, which
        # connects by address. Broadcast discovery would do nothing over wg0.
        WSDD2_DISABLE = "1";
        AVAHI_DISABLE = "1";
      };

      # ACCOUNT_<user>=<password> lives here rather than in `environment`,
      # because everything in this file is committed to a public repo. Create
      # it the same way as the WireGuard key and the portainer password:
      #   sudo install -d -m 700 /etc/samba
      #   printf 'ACCOUNT_n=1111\n' | sudo tee /etc/samba/container-env > /dev/null
      #   sudo chmod 600 /etc/samba/container-env
      environmentFiles = [ "/etc/samba/container-env" ];
    };

    # Binds to the wg0 address, so the tunnel has to exist first — same
    # dependency the other containers carry.
    systemd.services."docker-samba" = {
      after = [ "wireguard-wg0.service" ];
      requires = [ "wireguard-wg0.service" ];
    };
  };
}
