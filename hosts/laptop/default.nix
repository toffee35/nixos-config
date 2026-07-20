{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nvidia.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/sddm.nix
    ../../modules/desktop/thunar.nix
    ../../modules/development/docker.nix
    ../../modules/development/languages.nix
    ../../modules/apps/default.nix
    ../../modules/apps/antigravity.nix
    ../../modules/shell/zsh.nix
    ../../modules/hardware/legion-rgb.nix
    ../../modules/desktop/kitty.nix
  ];

  # Enable custom modules
  modules.desktop.hyprland.enable = true;
  modules.desktop.sddm.enable = true;
  modules.desktop.thunar.enable = true;
  modules.development.docker.enable = true;
  modules.development.languages.enable = true;
  modules.apps.enable = true;
  modules.apps.antigravity.enable = true;
  modules.shell.zsh.enable = true;
  modules.hardware.legion-rgb.enable = true;
  modules.desktop.kitty.enable = true;

  # Lenovo Legion kernel driver for advanced fan control and power profile monitoring
  boot.kernelModules = [ "lenovo-legion-module" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];

  # Enable battery conservation mode (limits charge to 60-80% at hardware level to preserve battery)
  systemd.tmpfiles.rules = [
    "w /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode - - - - 1"
  ];

  # Bootloader (Using GRUB as requested)
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "0NLaptopLegion";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Belgrade";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Laptop power management using auto-cpufreq (dynamic CPU tuning based on load & battery)
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "performance";
        turbo = "auto"; # Boosts to maximum only under load (saves battery/heat on low load)
      };
      battery = {
        governor = "powersave";
        turbo = "never"; # Disables turbo boost to save battery
      };
    };
  };
  powerManagement.enable = true;

  # Bluetooth support
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Audio (Pipewire)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable flakes and unified CLI
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Aggressive daily garbage collection & optimization (delete > 2d)
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 2d";
  };
  nix.settings.auto-optimise-store = true;
  nix.optimise = {
    automatic = true;
    dates = [ "daily" ];
  };

  # Additional binary caches
  nix.settings = {
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.n = {
    isNormalUser = true;
    description = "NixOS User";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" ];
  };

  # System packages - only bare minimum
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    lenovo-legion
  ];

  # Enable SSH (optional but useful)
  services.openssh.enable = true;

  # System version
  system.stateVersion = "26.05";
}
