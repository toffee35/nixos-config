{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.gnome-keyring;
in {
  options.modules.desktop.gnome-keyring = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable gnome-keyring as the freedesktop Secret Service provider.
        Hyprland ships no keyring of its own, so without this nothing owns
        org.freedesktop.secrets and apps that store credentials there (Zed,
        browsers, GitHub CLI) fail with "The name is not activatable".
      '';
    };
  };

  config = mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;

    # pam_gnome_keyring starts the daemon and unlocks the login keyring with the
    # password already typed at the prompt, so no second prompt appears. Only
    # `login` needs it: pam.d/sddm delegates its whole stack there via
    # `auth substack login` / `session include login`.
    security.pam.services.login.enableGnomeKeyring = true;

    # Graphical prompt for anything the daemon still needs to ask about.
    environment.systemPackages = [ pkgs.seahorse ];
  };
}
