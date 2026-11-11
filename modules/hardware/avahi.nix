{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.hardware.avahi;
in {
  options.modules.hardware.avahi = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Publish this host as <hostname>.local over mDNS so it stays reachable on any LAN without a fixed IP";
    };
  };

  config = mkIf cfg.enable {
    services.avahi = {
      enable = true;
      settings.publish = {
        disable-publishing = false;
        publish-addresses = true;
        publish-workstation = true;
      };
      # Resolve other .local names from this machine too (nsswitch integration).
      nssmdns4 = true;
      openFirewall = true;  # UDP 5353

      # Without this avahi advertises every interface it finds, including
      # docker0 and the per-container veth pairs — resolving <hostname>.local
      # then hands out 172.17.0.1, which is useless to anything off-host.
      # Restricted to the physical NICs so only the real LAN address goes out.
      settings.server.allow-interfaces = [ "wlp4s0" "eno1" ];
    };
  };
}
