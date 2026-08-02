{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.hardware.battery;

  # The only charging control this laptop exposes. It is a flag, not a
  # threshold: 1 tells the EC "stop charging" (its own cap sits around 60%),
  # 0 means "charge to 100%". There is no charge_control_end_threshold on
  # BAT0 and legion_laptop does not add one, so an exact limit can only be
  # approximated by flipping this flag around the wanted percentage.
  conservation = "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode";
  capacityFile = "/sys/class/power_supply/BAT0/capacity";

  # "limit" | "full". Lives in /run on purpose: every boot starts capped again.
  modeFile = "/run/battery-charge-mode";

  resume = toString (cfg.limit - cfg.hysteresis);

  enforce = pkgs.writeShellScript "battery-charge-enforce" ''
    mode=$(cat ${modeFile} 2>/dev/null || echo limit)
    capacity=$(cat ${capacityFile})
    current=$(cat ${conservation})

    if [ "$mode" = "full" ]; then
      want=0
    elif [ "$capacity" -ge ${toString cfg.limit} ]; then
      want=1
    elif [ "$capacity" -le ${resume} ]; then
      want=0
    else
      want=$current # inside the hysteresis band, leave it alone
    fi

    [ "$want" = "$current" ] || echo "$want" > ${conservation}
  '';

  toggle = pkgs.writeShellScriptBin "battery-charge-toggle" ''
    if [ "$(cat ${modeFile} 2>/dev/null)" = "full" ]; then
      echo limit > ${modeFile}
      ${pkgs.libnotify}/bin/notify-send -t 2000 -a "Battery" "Charge limit" \
        "On — holding around ${toString cfg.limit}%"
    else
      echo full > ${modeFile}
      ${pkgs.libnotify}/bin/notify-send -t 2000 -a "Battery" "Charge limit" \
        "Off — charging to 100%"
    fi
    ${enforce} # apply right away instead of waiting for the timer
  '';
in {
  options.modules.hardware.battery = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Hold the battery near a charge limit instead of charging it full";
    };

    limit = mkOption {
      type = types.ints.between 50 100;
      default = 80;
      description = "Percentage to stop charging at";
    };

    hysteresis = mkOption {
      type = types.ints.between 1 20;
      default = 3;
      description = ''
        How far below the limit the charge may fall before charging resumes.
        Too small a value makes the EC flip between charging and not on every
        poll, which is exactly what a charge limit is meant to avoid.
      '';
    };
  };

  config = mkIf cfg.enable {
    # The toggle runs as the user, so both files have to be group writable.
    systemd.tmpfiles.rules = [
      "z ${conservation} 0664 root users -"
      "f ${modeFile} 0664 root users - limit"
    ];

    systemd.services.battery-charge-limit = {
      description = "Hold the battery at ${toString cfg.limit}% (ideapad conservation mode)";
      after = [ "systemd-tmpfiles-setup.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${enforce}";
      };
    };

    systemd.timers.battery-charge-limit = {
      description = "Poll the battery level for the charge limit";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "1min";
      };
    };

    home-manager.users.${config.modules.user.name}.home.packages = [ toggle ];
  };
}
