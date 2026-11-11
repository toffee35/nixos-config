{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules                       # All modules auto-imported (each has enable = true by default)
  ];

  # ── Display ────────────────────────────────────────────────────────────────

  # The built-in CSOT MNG007DA1-1 panel advertises BT.2020 input in its EDID,
  # so Hyprland picks wide color gamut, but its primaries are plain sRGB
  # (R 0.640/0.330, G 0.300/0.600, B 0.150/0.060). Pin sRGB so colors are not
  # remapped for a gamut the panel cannot show.
  # It also advertises HDR (ST2084, ~500 nit), so Hyprland 0.57 switches it to
  # HDR whenever a window goes fullscreen (auto HDR): a modeset blink and a
  # washed-out picture. supports_hdr=-1 hides HDR on this panel only.
  modules.desktop.hyprland.monitors = [
    "eDP-1,preferred,auto,1,cm=srgb,supports_hdr=-1"
    ",preferred,auto,1"
  ];

  # ── Boot & Kernel ──────────────────────────────────────────────────────────

  # These packages install .ko files directly, bypassing the kernel's new
  # kmodigest signing step. The combined module tree requires their certificates.
  boot.kernelPackages = pkgs.linuxPackages.extend (_final: prev:
    let
      signModules = package: package.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          find "$out/lib/modules" -type f -name '*.ko' \
            -exec ${pkgs.kmodigest}/bin/kmodigest {} \;
        '';
      });
    in {
      lenovo-legion-module = signModules prev.lenovo-legion-module;
      zenpower = signModules prev.zenpower;
    });

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
    restartIfChanged = false;
    unitConfig = {
      ConditionKernelVersion = config.boot.kernelPackages.kernel.modDirVersion;
      ConditionPathExists = "!/sys/module/legion_laptop";
    };
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

  # No swap of any kind existed — no partition, no file, no zram — so a spike
  # had nowhere to go but the OOM killer, and systemd-oomd manages no slice
  # here either. zram is compressed swap inside RAM: it never touches the SSD,
  # and zstd gets roughly 3:1 on anonymous pages, so half the RAM offered as
  # zram buys back several gigabytes of headroom rather than 13.
  #
  # Sized at 50% because that is the upper bound of what is useful: zram pages
  # still occupy RAM once compressed, and a larger pool mostly displaces the
  # page cache.
  # Default is 60, tuned for swap on a spinning disk: the kernel prefers to
  # drop the page cache over swapping. With zram the trade flips — writing a
  # cold anonymous page costs microseconds of zstd, whereas re-reading a
  # dropped cache page costs a real SSD round trip. 150 leans on zram first,
  # which is the point of having it.
  boot.kernel.sysctl."vm.swappiness" = 150;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # ── Hardware: Power Management ─────────────────────────────────────────────
  powerManagement.enable = true;

  # Charge limiting lives in modules/hardware/battery.nix (limit + toggle).

  # One owner for CPU/EPP/boost; amd-pstate still adjusts frequency with load.
  services.auto-cpufreq.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
    };
  };

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
