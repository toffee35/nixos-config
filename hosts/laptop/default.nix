{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules                       # All modules auto-imported (each has enable = true by default)
  ];

  # ── Boot & Kernel ──────────────────────────────────────────────────────────
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Lenovo Legion kernel driver for advanced fan control and power profile monitoring
  boot.kernelModules = [ "lenovo-legion-module" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];

  # ── Networking ─────────────────────────────────────────────────────────────
  networking.hostName = "0NLaptopLegion";
  networking.networkmanager.enable = true;

  # ── Locale ─────────────────────────────────────────────────────────────────
  time.timeZone = "Europe/Belgrade";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Hardware: Power Management ─────────────────────────────────────────────
  powerManagement.enable = true;

  # Enable battery conservation mode (limits charge to 60-80% at hardware level)
  systemd.tmpfiles.rules = [
    "w /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode - - - - 1"
  ];

  # Dynamic CPU tuning based on load & battery state
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "performance";
        turbo = "auto";             # Boosts to maximum only under load
      };
      battery = {
        governor = "powersave";
        turbo = "never";            # Disables turbo boost to save battery
      };
    };
  };

  # ── Hardware: Audio ────────────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ── Hardware: Bluetooth ────────────────────────────────────────────────────
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # ── User Account ───────────────────────────────────────────────────────────
  users.users.${config.modules.user.name} = {
    isNormalUser = true;
    description = "NixOS User";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" ];
  };

  # ── System Packages (bare minimum) ────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    lenovo-legion
  ];

  # ── Services ───────────────────────────────────────────────────────────────
  services.openssh.enable = true;

  system.stateVersion = "26.05";
}
