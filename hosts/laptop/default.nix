{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules                       # All modules auto-imported (each has enable = true by default)
  ];

  # ── Boot & Kernel ──────────────────────────────────────────────────────────

  # Lenovo Legion kernel driver for advanced fan control and power profile monitoring.
  #
  # Two problems, verified live before writing this:
  # 1. The custom module's legion-laptop.ko collides in name/path with the in-tree
  #    mainline driver of the same name. Both `modprobe legion-laptop` (explicit
  #    name) and the module-tree merge consistently resolve to the STOCK file, not
  #    the custom one — blacklisting only stops automatic hotplug-triggered loads,
  #    not an explicit modprobe by name, so we sidestep name-based resolution
  #    entirely and insmod the custom .ko by its exact store path instead.
  # 2. Even loaded, the custom module silently skips registering its hwmon/
  #    fan-control interface unless given `force=1` — LenovoLegionLinux has a
  #    hardcoded per-model allowlist and this laptop isn't recognized on it, so
  #    without force it loads "successfully" but legion_cli/legion_gui just see
  #    "hwmon dir not found".
  #
  # No off-the-shelf NixOS module handles this (checked nixos-hardware's
  # lenovo/legion/16ach6h — GPU switching only, no fan-control code; LenovoLegionLinux
  # itself ships no nixosModule) — this is a hand-rolled but standard NixOS pattern.
  boot.blacklistedKernelModules = [ "legion_laptop" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];

  systemd.services.legion-laptop-module = {
    description = "Load custom LenovoLegionLinux legion-laptop.ko (force=1, overrides in-tree driver of the same name)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart =
        let
          mod = config.boot.kernelPackages.lenovo-legion-module;
          kver = config.boot.kernelPackages.kernel.modDirVersion;
        in
        "${pkgs.kmod}/bin/insmod ${mod}/lib/modules/${kver}/kernel/drivers/platform/x86/legion-laptop.ko force=1";
    };
  };

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
