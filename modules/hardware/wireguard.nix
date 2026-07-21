{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.hardware.wireguard;
in {
  options.modules.hardware.wireguard = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable a local WireGuard VPN server for LAN-only access";
    };

    port = mkOption {
      type = types.port;
      default = 51820;
      description = "UDP port WireGuard listens on";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [ cfg.port ];

    # Peers connected over wg0 get full access to whatever's listening on the
    # host (SSH, Ollama, Docker admin UIs, etc.) — not a per-port allowlist.
    # Doesn't affect Docker's own published ports (those bypass this firewall
    # entirely; they're restricted by which IP they're bound to instead, see
    # modules/development/docker.nix).
    networking.firewall.trustedInterfaces = [ "wg0" ];

    # The private key is generated on-machine and kept outside the (public)
    # git repo — see modules/hardware/wireguard.nix's neighboring README note.
    # Generate it with:
    #   sudo install -d -m 700 /etc/wireguard
    #   wg genkey | sudo tee /etc/wireguard/private.key > /dev/null
    #   sudo chmod 600 /etc/wireguard/private.key
    networking.wireguard.interfaces.wg0 = {
      ips = [ "10.100.0.1/24" ];
      listenPort = cfg.port;
      privateKeyFile = "/etc/wireguard/private.key";

      # Add one entry per client device.
      peers = [
        {
          # phone
          publicKey = "AWFWdqskF1F9rgxesBkdLHSOMBvBVFU4CIp+TjJM8mY=";
          allowedIPs = [ "10.100.0.2/32" ];
        }
      ];
    };
  };
}
