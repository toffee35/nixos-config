{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules                       # All modules auto-imported (each has enable = true by default)
  ];

  # ── Boot & Kernel ──────────────────────────────────────────────────────────

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

  # Enable battery conservation mode by default (limits charge to 60-80% at
  # hardware level), but leave it group-writable so battery-conservation-toggle
  # (see below) can flip it to full-charge mode without sudo, e.g. before travel.
  systemd.tmpfiles.rules = [
    "w /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode - - - - 1"
    "z /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode 0664 root users -"
  ];

  home-manager.users.${config.modules.user.name}.home.packages = [
    (pkgs.writeShellScriptBin "battery-conservation-toggle" ''
      FILE=/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
      if [ "$(cat "$FILE")" = "1" ]; then
        echo 0 > "$FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 -a "Battery" "Conservation mode" "Disabled — charging to 100%"
      else
        echo 1 > "$FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 -a "Battery" "Conservation mode" "Enabled — charging capped ~60-80%"
      fi
    '')
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
    vim
    curl
    wget
    lenovo-legion
  ];

  # ── Services ───────────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  system.stateVersion = "26.05";
}
