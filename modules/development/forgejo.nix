{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.development.forgejo;
  user = config.modules.user.name;
in {
  options.modules.development.forgejo = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable a self-hosted Forgejo git server";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "HTTP port Forgejo is published on";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.forgejo = {
      # Forgejo's registry publishes no `latest` tag — pulling it fails with
      # "not found" — so this tracks the current major line instead, which
      # still picks up patch releases.
      image = "codeberg.org/forgejo/forgejo:16";

      # Same reasoning as portainer/transmission in ./docker.nix: Docker's
      # published ports bypass the NixOS firewall, so the bind address is what
      # actually limits reach. Loopback plus the WireGuard address only.
      ports = [
        "127.0.0.1:${toString cfg.port}:3000"
        "10.100.0.1:${toString cfg.port}:3000"
      ];

      volumes = [
        "forgejo_data:/data"
        "/etc/forgejo/admin-password:/run/admin-password:ro"
      ];

      environment = {
        USER_UID = "1000";
        USER_GID = "100";
        TZ = "Europe/Belgrade";

        # Skips the web installer, so the instance is usable on first start
        # rather than waiting on a setup wizard.
        FORGEJO__security__INSTALL_LOCK = "true";

        FORGEJO__server__DOMAIN = "10.100.0.1";
        FORGEJO__server__ROOT_URL = "http://10.100.0.1:${toString cfg.port}/";
        FORGEJO__server__HTTP_PORT = "3000";

        # No built-in SSH server: git goes over HTTP. This is deliberate — the
        # built-in server would otherwise want port 22, which sshd already owns
        # (see hosts/laptop/default.nix). Nothing to conflict with this way.
        FORGEJO__server__DISABLE_SSH = "true";

        # Matches the password actually used below; Forgejo rejects anything
        # shorter than MIN_PASSWORD_LENGTH at user creation.
        FORGEJO__security__MIN_PASSWORD_LENGTH = "4";
        FORGEJO__security__PASSWORD_COMPLEXITY = "off";
      };
    };

    # Binds to the wg0 address, so the tunnel has to exist first — same
    # dependency the other two containers carry in ./docker.nix.
    systemd.services."docker-forgejo" = {
      after = [ "wireguard-wg0.service" ];
      requires = [ "wireguard-wg0.service" ];
    };

    # Forgejo has no flag to bootstrap an admin (unlike portainer's
    # --admin-password-file), only a CLI subcommand against a running
    # instance. Declaring it as a oneshot keeps it in the config instead of
    # being a command to remember: it creates the account if missing and does
    # nothing when it already exists.
    systemd.services.forgejo-configure = {
      description = "Create the initial Forgejo admin account if it does not exist";
      after = [ "docker-forgejo.service" ];
      requires = [ "docker-forgejo.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # `-u git` on every exec: the image's entrypoint drops to the git user,
        # but docker exec defaults back to root, and Forgejo hard-refuses to
        # run as root ("Forgejo is not supposed to be run as root. Sorry.").
        #
        # The container is up before Forgejo has finished initialising its
        # database, and `admin user list` fails until then.
        for _ in $(seq 60); do
          docker exec -u git forgejo forgejo admin user list > /dev/null 2>&1 && break
          sleep 1
        done

        if docker exec -u git forgejo forgejo admin user list 2>/dev/null | grep -qw ${user}; then
          echo "admin ${user} already exists, nothing to do"
          exit 0
        fi

        docker exec -u git forgejo forgejo admin user create \
          --admin \
          --username ${user} \
          --email nailzagru@gmail.com \
          --password "$(cat /etc/forgejo/admin-password)" \
          --must-change-password=false
      '';
    };
  };
}
