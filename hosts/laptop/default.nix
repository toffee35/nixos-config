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

  # Charge limiting lives in modules/hardware/battery.nix (limit + toggle).

  # Dynamic CPU tuning based on load & battery state
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        # Under amd-pstate-epp "powersave" is the dynamic mode, not a slow one:
        # it still ramps to the full 4.28 GHz under load, and drops back toward
        # the 412 MHz floor when there is nothing to do. "performance" pinned
        # every core at ~3.27 GHz permanently — a lower ceiling than powersave
        # reaches, yet hot and loud at idle, since the cores never wound down.
        governor = "powersave";
        energy_performance_preference = "balance_performance";
        turbo = "auto";             # Boosts to maximum only under load
      };
      battery = {
        governor = "powersave";
        turbo = "never";            # Disables turbo boost to save battery
      };
    };
  };

  # ── Hardware: Audio ────────────────────────────────────────────────────────

  # Without this pipewire runs as SCHED_OTHER with "Max realtime priority 0",
  # so its audio thread gets preempted by ordinary processes whenever the
  # machine is busy. That shows up as crackling under load (many streams in a
  # Discord call, say) while idle playback stays clean — xruns were piling up
  # on alsa_output.pci-0000_05_00.6.analog-stereo.
  security.rtkit.enable = true;

  # The HDA codec otherwise powers down after a second of silence and clicks on
  # every wake. In a voice call, where streams stop and start constantly with
  # voice activity, that turns into near-continuous crackling. Verified by
  # toggling the same parameter at runtime: crackling stopped at 0 and came
  # back after a reboot reset it to 1.
  #
  # Costs a little idle power on battery, which is why the kernel defaults it on.
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0 power_save_controller=N
  '';

  # TLP comes from nixos-hardware's common/pc/laptop profile, not from this
  # config, and its defaults are SOUND_POWER_SAVE_ON_AC=1 / ON_BAT=1 — it does
  # not distinguish mains from battery for audio, so it re-asserts power saving
  # over the modprobe setting above on boot and on every power-source change.
  services.tlp.settings = {
    SOUND_POWER_SAVE_ON_AC = 0;
    SOUND_POWER_SAVE_ON_BAT = 0;
  };

  # Discord asks for a 360-frame period (7.5 ms) and PipeWire obliges by
  # dragging the whole graph down to it, EasyEffects' extra node included.
  # That budget is too tight here: over one session the sink and easyeffects_sink
  # piled up ~800 and ~1050 xruns, which is the crackling during calls. Clamping
  # the floor at 1024 (21 ms) keeps one client from setting the pace for
  # everyone; 21 ms of added latency is irrelevant for voice chat.
  services.pipewire.extraConfig.pipewire."10-min-quantum" = {
    "context.properties" = {
      "default.clock.min-quantum" = 1024;
    };
  };

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

    # Phone's SSH key. Only the PUBLIC half lives here — safe to commit; the
    # private half lives on the phone alone and is never stored in this repo.
    # Password auth is off (see services.openssh below), so this list is the
    # only way in over SSH.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILrzYIFt3FDb89y0repJSLZrO/gmTnPWr+POb1S14urq phone@0NLaptopLegion"
    ];
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
