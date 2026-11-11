{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.gracefulShutdown;
  user = config.modules.user.name;

  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  jq = "${pkgs.jq}/bin/jq";

  # Closes every app while the compositor is still alive. Left to the normal
  # shutdown order, Hyprland goes first: its clients lose the display and die
  # mid-flight, which OBS reports as a crash (the next start offers safe mode)
  # and Chrome records as one (the next start asks to restore tabs).
  #
  # Chrome is sent SIGTERM rather than having its windows closed: closing
  # windows one by one makes it drop every window but the last from the saved
  # session. SIGTERM to the browser process ends it as a whole — tested on a
  # throwaway profile, exit_type comes out "SessionEnded", not "Crashed".
  #
  # Everything else gets closewindow, i.e. the same as clicking its close
  # button — tested with OBS, which then clears its crash sentinel.
  #
  # DRY_RUN=1 prints the actions without taking them.
  close-apps = pkgs.writeShellScriptBin "close-apps" ''
    run() { if [ -n "$DRY_RUN" ]; then echo "would: $*"; else "$@" > /dev/null; fi; }

    # The browser process itself: executable named exactly chrome/chromium and
    # no --type= argument. Renderers and the GPU process carry --type=; the
    # crashpad handlers have neither, but their executable is named
    # chrome_crashpad_handler.
    browsers=""
    for pid in $(${pkgs.procps}/bin/pgrep -f '(google-chrome|chromium)'); do
      # /proc/PID/exe, not argv[0]: Chrome rewrites its argv into one
      # space-joined process title, so argv[0] is the whole command line.
      exe=$(${pkgs.coreutils}/bin/basename "$(${pkgs.coreutils}/bin/readlink /proc/$pid/exe 2>/dev/null)")
      case "$exe" in chrome|chromium|.chromium-wrapped) ;; *) continue ;; esac
      tr '\0' ' ' < /proc/$pid/cmdline 2>/dev/null | grep -q -- '--type=' && continue
      browsers="$browsers $pid"
    done
    for pid in $browsers; do run kill -TERM "$pid"; done

    # Every remaining window, except the browsers already being shut down.
    ${hyprctl} clients -j \
      | ${jq} -r '.[] | select((.class | ascii_downcase | test("chrom")) | not) | "\(.address) \(.pid)"' \
      | while read -r addr pid; do
          run ${hyprctl} dispatch "hl.dsp.window.close({window=\"address:$addr\"})"
          echo "$pid" >> "''${XDG_RUNTIME_DIR:-/tmp}/close-apps.pids"
        done

    [ -n "$DRY_RUN" ] && exit 0

    # Give them time to save and exit, bounded by logind's InhibitDelayMaxSec.
    pids="$browsers $(cat "''${XDG_RUNTIME_DIR:-/tmp}/close-apps.pids" 2>/dev/null)"
    rm -f "''${XDG_RUNTIME_DIR:-/tmp}/close-apps.pids"
    for _ in $(seq 40); do
      alive=""
      for p in $pids; do kill -0 "$p" 2>/dev/null && alive=1; done
      [ -z "$alive" ] && break
      sleep 0.25
    done
  '';

  # Holds a logind "delay" inhibitor. Whatever starts a shutdown or reboot —
  # the power button, `poweroff`, `reboot`, `sudo reboot`, the SDDM menu —
  # goes through logind, which first broadcasts PrepareForShutdown(true) and
  # waits for delay-lock holders to let go. That window is when close-apps
  # runs, with Hyprland still up. Exiting releases the lock and the shutdown
  # carries on.
  watcher = pkgs.writeShellScript "close-apps-on-shutdown" ''
    ${pkgs.dbus}/bin/dbus-monitor --system \
      "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForShutdown'" \
      | while read -r line; do
          case "$line" in
            *"boolean true"*) ${close-apps}/bin/close-apps; exit 0 ;;
          esac
        done
  '';
in {
  options.modules.desktop.gracefulShutdown = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Close apps cleanly before shutdown, reboot or leaving Hyprland";
    };
  };

  config = mkIf cfg.enable {
    # logind waits at most this long for delay-lock holders (default 5 s).
    services.logind.settings.Login.InhibitDelayMaxSec = 15;

    home-manager.users.${user} = {
      home.packages = [ close-apps ];

      systemd.user.services.close-apps-on-shutdown = {
        Unit = {
          Description = "Close apps cleanly before shutdown or reboot";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=shutdown --mode=delay --who=close-apps --why=\"Closing apps cleanly\" ${watcher}";
          # If a shutdown is requested and then cancelled, the lock is gone;
          # come back and take it again.
          Restart = "always";
          RestartSec = 1;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # $mod+M quits Hyprland directly, which would crash every app the same
      # way; close them first.
      wayland.windowManager.hyprland.settings.bind = [
        { _args = [ "SUPER + M" (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("close-apps && ${hyprctl} dispatch 'hl.dsp.exit()'")'') ]; }
      ];
    };
  };
}
