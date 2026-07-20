{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.nix-settings;
in {
  options.modules.nix-settings = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable common Nix settings (flakes, GC, binary caches, allowUnfree)";
    };
  };

  config = mkIf cfg.enable {
    # Enable flakes and unified CLI
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Allow unfree packages globally
    nixpkgs.config.allowUnfree = true;

    # Safe daily garbage collection & optimization (delete > 14d)
    nix.gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 14d";
    };
    nix.settings.auto-optimise-store = true;
    nix.optimise = {
      automatic = true;
      dates = [ "daily" ];
    };

    # System-level binary caches (for the installed system).
    # Note: flake.nix nixConfig sets the same caches for nix CLI on any machine.
    nix.settings = {
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://cachix.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cachix.cachix.org-1:eWNHQldwUO7g2aNKvzY5aa4a2/S5S/EJ5Ry2m7JU5Bo="
      ];
    };
  };
}
