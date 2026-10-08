{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.hardware.batteryNotify;

  thresholds = [ 50 25 12 6 3 1 ];

  # BAT is overridable only so the logic can be exercised against a fake
  # sysfs directory; in normal use it is always BAT0.
  notify = pkgs.writeShellScript "battery-notify" ''
    bat=''${BAT:-/sys/class/power_supply/BAT0}
    state="''${XDG_RUNTIME_DIR:-/tmp}/battery-notified"

    cap=$(cat "$bat/capacity")
    status=$(cat "$bat/status")

    # Anything but discharging — charging, full, or the conservation-mode
    # "Not charging" — re-arms every threshold for the next discharge.
    if [ "$status" != "Discharging" ]; then
      rm -f "$state"
      exit 0
    fi

    last=$(cat "$state" 2>/dev/null || echo 101)

    # Only the lowest threshold crossed since the last notification fires, so
    # unplugging at 20% yields one "25%" warning rather than 50% and 25% at once.
    hit=""
    for t in ${concatMapStringsSep " " toString thresholds}; do
      if [ "$cap" -le "$t" ] && [ "$t" -lt "$last" ]; then hit=$t; fi
    done
    [ -z "$hit" ] && exit 0

    if [ "$hit" -le 12 ]; then urgency=critical; else urgency=normal; fi
    ${pkgs.libnotify}/bin/notify-send -u "$urgency" -a "Battery" \
      "Battery at $cap%" "Below $hit% — plug in the charger"
    echo "$hit" > "$state"
  '';
in {
  options.modules.hardware.batteryNotify = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Desktop notifications at ${concatMapStringsSep ", " toString thresholds}% battery while discharging";
    };
  };

  config = mkIf cfg.enable {
    # A user unit rather than a system one: notify-send needs the session bus.
    home-manager.users.${config.modules.user.name} = {
      systemd.user.services.battery-notify = {
        Unit.Description = "Warn about low battery";
        Service = {
          Type = "oneshot";
          ExecStart = "${notify}";
        };
      };
      systemd.user.timers.battery-notify = {
        Unit.Description = "Check battery level every minute";
        Timer = {
          OnBootSec = "1min";
          OnUnitActiveSec = "1min";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
