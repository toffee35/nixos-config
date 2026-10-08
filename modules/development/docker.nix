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

    # Docker keeps its own garbage and nix.gc never touches it: stopped
    # containers, dangling images and the build cache added up to ~21 GB here.
    # NixOS has this built in, so no hand-rolled unit — weekly, and only things
    # older than a week.
    #
    # allVolumes stays false: the volumes hold the portainer, transmission and
    # ollama data. No `-a` either, which would drop images that are merely not
    # running.
    virtualisation.docker.autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--filter" "until=168h" ];
      allVolumes.enable = false;
    };

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
            "/etc/portainer/admin-password:/run/admin-password:ro"
          ];
          # Bootstraps the admin account on first start, so the UI never sits in
          # its "no admin yet" state and never expires into /timeout.html.
          # The username is always `admin` — portainer has no flag for it, and
          # authentication cannot be turned off at all. Rename in the UI if
          # wanted. Ignored once an admin exists in portainer_data.
          #
          # The password is kept out of this (public) repo, same as the
          # WireGuard key — see modules/hardware/wireguard.nix. Create it with:
          #   sudo install -d -m 700 /etc/portainer
          #   printf '1111' | sudo tee /etc/portainer/admin-password > /dev/null
          #   sudo chmod 600 /etc/portainer/admin-password
          #
          # `-H` pre-connects the local Docker socket as an environment named
          # "primary" at first start, so the UI skips the onboarding wizard and
          # no agent container is needed.
          cmd = [
            "--admin-password-file" "/run/admin-password"
            "-H" "unix:///var/run/docker.sock"
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

    # Portainer stores its settings in portainer.db inside the volume, not in a
    # config file, so this one setting can't be a Nix file — it has to be an
    # API call against the running instance. Declaring it as a oneshot keeps it
    # in the config anyway: it re-applies on every boot and after a volume wipe,
    # instead of being a command someone has to remember to run by hand.
    #
    # What it does: portainer requires a 12-character admin password and flags
    # shorter ones with forceChangePassword, which makes the UI demand a change
    # at every login. Lowering RequiredPasswordLength clears that flag.
    # Re-running is harmless.
    systemd.services.portainer-configure = {
      description = "Apply Portainer settings that only exist in its runtime database";
      after = [ "docker-portainer.service" ];
      requires = [ "docker-portainer.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.curl pkgs.jq ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        api=http://127.0.0.1:9000/api

        # The container is "started" as soon as docker returns, but the HTTP
        # server needs a moment more before it answers.
        for _ in $(seq 60); do
          curl -sf "$api/system/status" > /dev/null && break
          sleep 1
        done

        jwt=$(jq -nc --arg p "$(cat /etc/portainer/admin-password)" \
                '{username: "admin", password: $p}' \
              | curl -sf -X POST "$api/auth" -H 'Content-Type: application/json' -d @- \
              | jq -r .jwt)

        curl -sf -X PUT "$api/settings" \
          -H "Authorization: Bearer $jwt" \
          -H 'Content-Type: application/json' \
          -d '{"InternalAuthSettings":{"RequiredPasswordLength":1}}' > /dev/null
      '';
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
