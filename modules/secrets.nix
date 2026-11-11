{ config, lib, ... }:
let
  specs = {
    wireguard = {
      legacy = "/etc/wireguard/private.key";
      restartUnits = [ "wireguard-wg0.service" ];
    };
    samba = {
      legacy = "/etc/samba/container-env";
      restartUnits = [ "docker-samba.service" ];
    };
    portainer = {
      legacy = "/etc/portainer/admin-password";
      restartUnits = [ "docker-portainer.service" ];
    };
    webui = {
      legacy = "/var/lib/open-webui/secret.env";
      restartUnits = [ "docker-open-webui.service" ];
    };
  };
  encrypted = name: ../secrets + "/${name}.json";
  migrated = name: builtins.pathExists (encrypted name);
in
{
  options.modules.secrets.paths = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    readOnly = true;
    description = "Migrated sops secret paths, with legacy paths until bootstrap.";
  };
  config = {
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    sops.gnupg.sshKeyPaths = [ ];
    sops.secrets = lib.mapAttrs (name: spec: {
      sopsFile = encrypted name;
      format = "binary";
      mode = "0400";
      inherit (spec) restartUnits;
    }) (lib.filterAttrs (name: _: migrated name) specs);
    modules.secrets.paths = lib.mapAttrs (
      name: spec: if migrated name then config.sops.secrets.${name}.path else spec.legacy
    ) specs;
  };
}
