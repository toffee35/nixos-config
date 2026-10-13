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

  # Crackling happens only on the built-in speakers and only while a Discord
  # voice channel is open. Discord asks for a 360-frame period and the graph
  # follows it; the analog output cannot keep up at that size, even though the
  # xrun counters stay flat throughout (measured during the symptom). The same
  # audio through Bluetooth headphones is clean, so the digital path is fine.
  #
  # Pinning the minimum only for this one node, rather than for the whole
  # graph: a global default.clock.min-quantum was tried first and stopped
  # Bluetooth A2DP from negotiating a stream at all.
  services.pipewire.wireplumber.extraConfig."51-speaker-quantum" = {
    "monitor.alsa.rules" = [
      {
        matches = [ { "node.name" = "alsa_output.pci-0000_05_00.6.analog-stereo"; } ];
        actions.update-props = {
          "api.alsa.period-size" = 1024;
          "node.force-quantum" = 1024;
        };
      }
    ];
  };

  # Bluetooth headphones went silent after connecting, with EasyEffects
  # routing to them and nothing in the logs but "links failed to activate".
  # The transport was seen flapping idle -> active -> idle: PipeWire suspends
  # an idle node after a few seconds and releases the A2DP transport, and on
  # the next sound these headphones fail to re-acquire it. A fresh reconnect
  # only helped because it opened the transport anew.
  #
  # Never suspending Bluetooth outputs keeps the transport held for as long
  # as the headphones are connected. Cost: the headphones get a silent stream
  # and may not enter their own idle power-saving while connected.
  services.pipewire.wireplumber.extraConfig."52-bluetooth-no-suspend" = {
    "monitor.bluez.rules" = [
      {
        matches = [ { "node.name" = "~bluez_output.*"; } ];
        actions.update-props = {
          "session.suspend-timeout-seconds" = 0;
        };
      }
    ];
  };

  # WirePlumber flips Bluetooth headphones to the headset profile (HFP/mSBC,
  # narrowband) as soon as anything starts recording — joining a call is
  # enough. The microphone here is the QuadCast, never the headset, so the
  # switch only ever cost audio quality. Keep them in A2DP.
  # During calls the A2DP transport would drop and bluez then refused to hand
  # it back ("Acquire ... org.bluez.Error.NotAuthorized", with its own log
  # saying the endpoint is "in bad state"); seconds later the HFP endpoint came
  # up and the headphones were stuck in headset mode, where A2DP disappears
  # from the profile list entirely and nothing plays. Reconnecting was the only
  # cure, because it builds the transport anew. Happened on 22, 24, 27 and 29
  # September — every time there was a call.
  #
  # With only the A2DP roles offered, there is no headset profile to fall into:
  # a dropped transport is simply re-acquired. The headset's own microphone
  # stops existing for the system, which costs nothing here — the microphone is
  # the QuadCast, and these headphones are only ever used for output.
  services.pipewire.wireplumber.extraConfig."54-bluetooth-a2dp-only" = {
    "monitor.bluez.properties" = {
      "bluez5.roles" = [ "a2dp_sink" "a2dp_source" ];

      # SBC only. With AAC (which the HAYLOU advertises and WirePlumber picked
      # by default) BlueZ refused the transport outright:
      #   Acquire .../sep2/fd0 returned error: org.bluez.Error.NotAuthorized
      # followed by "2 of 2 PipeWire links failed to activate" and a silent
      # sink. On SBC the same device acquires the transport and plays. SBC-XQ
      # is left out on purpose: its higher bitrate is what used to crackle.
      "bluez5.codecs" = [ "sbc" ];
    };
  };

  services.pipewire.wireplumber.extraConfig."53-bluetooth-no-autoswitch" = {
    "wireplumber.settings" = {
      "bluetooth.autoswitch-to-headset-profile" = false;
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

    # Phone's SSH keys. Only the PUBLIC halves live here — safe to commit; the
    # private halves live on the phone alone and are never stored in this repo.
    # Password auth is off (see services.openssh below), so this list is the
    # only way in over SSH.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILrzYIFt3FDb89y0repJSLZrO/gmTnPWr+POb1S14urq phone@0NLaptopLegion"
      # Termux on the same phone
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHp2w1weXzLyroePMbPFRvCC4OPrmLc3H6Zi2Gu7haC0 termux-phone"
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
