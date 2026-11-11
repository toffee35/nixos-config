{ config, lib, ... }:

{
  options.modules.hardware.audio.enable = lib.mkEnableOption "PipeWire audio and Bluetooth" // {
    default = true;
  };

  config = lib.mkIf config.modules.hardware.audio.enable {
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
  };
}
