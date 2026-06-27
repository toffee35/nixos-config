{pkgs, ...}: {
  services.polybar = {
    enable = true;
    package = pkgs.polybar.override {
      alsaSupport = true;
      githubSupport = true;
      mpdSupport = true;
      pulseSupport = true;
    };

    script = "polybar main &";

    config = {
      "colors" = {
        background    = "#1e1e2e";
        background-alt = "#313244";
        foreground    = "#cdd6f4";
        primary       = "#89b4fa";
        secondary     = "#cba6f7";
        alert         = "#f38ba8";
        warning       = "#f9e2af";
        success       = "#a6e3a1";
        disabled      = "#6c7086";
      };

      "bar/main" = {
        width  = "100%";
        height = "28pt";
        radius = 0;

        background = "\${colors.background}";
        foreground = "\${colors.foreground}";

        line-size  = "2pt";
        border-size = "0pt";
        border-color = "#00000000";

        padding-left  = 1;
        padding-right = 1;
        module-margin = 1;

        separator            = "|";
        separator-foreground = "\${colors.disabled}";

        font-0 = "JetBrains Mono:size=10;2";
        font-1 = "Font Awesome 6 Free Solid:size=10;2";
        font-2 = "Font Awesome 6 Brands:size=10;2";

        # Добавлен network между xwindow и правой панелью
        modules-left   = "bspwm xwindow";
        modules-center = "date";
        modules-right  = "network filesystem pulseaudio backlight memory cpu temperature battery tray";

        cursor-click  = "pointer";
        cursor-scroll = "ns-resize";

        enable-ipc = true;

        tray-position = "right";
        tray-detached = false;
        tray-maxsize  = 16;
        tray-padding  = 2;
        tray-scale    = 1;
      };

      # ─── Рабочие столы ───────────────────────────────────────────────
      "module/bspwm" = {
        type = "internal/bspwm";

        label-focused            = "%index%";
        label-focused-background = "\${colors.background-alt}";
        label-focused-underline  = "\${colors.primary}";
        label-focused-padding    = 1;

        label-occupied         = "%index%";
        label-occupied-padding = 1;

        label-urgent            = "%index%!";
        label-urgent-background = "\${colors.alert}";
        label-urgent-padding    = 1;

        label-empty            = "%index%";
        label-empty-foreground = "\${colors.disabled}";
        label-empty-padding    = 1;
      };

      # ─── Заголовок окна ──────────────────────────────────────────────
      "module/xwindow" = {
        type  = "internal/xwindow";
        label = "%title:0:60:...%";
        label-foreground = "\${colors.disabled}";
      };

      # ─── Дата/время (клик переключает формат) ────────────────────────
      "module/date" = {
        type     = "internal/date";
        interval = 1;

        date     = "%H:%M";
        date-alt = "%Y-%m-%d %H:%M:%S";

        label            = "%{F#89b4fa}%{F-} %date%";
        label-foreground = "\${colors.primary}";
      };

      # ─── Сеть ────────────────────────────────────────────────────────
      # Поменяй interface-0 на своё имя (ip link, напр. wlan0 / enp3s0)
      "module/network" = {
        type      = "internal/network";
        interface-type = "wireless";   # или "wired"
        interval  = 3;

        format-connected    = "%{F#89b4fa}%{F-} <label-connected>";
        label-connected     = "%essid% %{F#a6e3a1}▲%upspeed:6%%{F-} %{F#89b4fa}▼%downspeed:6%%{F-}";

        format-disconnected    = "<label-disconnected>";
        label-disconnected     = "%{F#f38ba8}%{F-} offline%{F-}";
        label-disconnected-foreground = "\${colors.disabled}";

        format-packetloss    = "<label-packetloss>";
        label-packetloss     = "%{F#f9e2af}%{F-} %essid%%{F-}";
      };

      # ─── Диск ────────────────────────────────────────────────────────
      "module/filesystem" = {
        type     = "internal/fs";
        interval = 25;

        mount-0 = "/";

        format-mounted  = "%{F#89b4fa}%{F-} <label-mounted>";
        label-mounted   = "%mountpoint% %percentage_used%%";

        format-unmounted  = "<label-unmounted>";
        label-unmounted   = "%mountpoint% N/A";
        label-unmounted-foreground = "\${colors.disabled}";
      };

      # ─── Громкость (скролл меняет уровень) ───────────────────────────
      "module/pulseaudio" = {
        type = "internal/pulseaudio";
        use-ui-max = false;

        format-volume = "%{F#89b4fa}%{F-} <label-volume>";
        label-volume  = "%percentage%%";

        format-muted            = "<label-muted>";
        label-muted             = "%{F#6c7086}%{F-} muted";
        label-muted-foreground  = "\${colors.disabled}";

        click-right  = "pavucontrol &";
        scroll-up    = "pactl set-sink-volume @DEFAULT_SINK@ +2%";
        scroll-down  = "pactl set-sink-volume @DEFAULT_SINK@ -2%";
        click-middle = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
      };

      # ─── Яркость (скролл меняет) ──────────────────────────────────────
      # Требует: xorg.xbacklight или brightnessctl в PATH
      "module/backlight" = {
        type     = "internal/backlight";
        card     = "intel_backlight";   # ls /sys/class/backlight/
        use-actual-brightness = true;

        format = "%{F#89b4fa}%{F-} <label>";
        label  = "%percentage%%";

        scroll-up   = "brightnessctl set +5%";
        scroll-down = "brightnessctl set 5%-";
      };

      # ─── Память ───────────────────────────────────────────────────────
      "module/memory" = {
        type     = "internal/memory";
        interval = 2;

        format = "%{F#89b4fa}%{F-} <label>";
        label  = "RAM %percentage_used:2%%";
      };

      # ─── CPU ─────────────────────────────────────────────────────────
      "module/cpu" = {
        type     = "internal/cpu";
        interval = 2;

        format = "%{F#89b4fa}%{F-} <label>";
        label  = "CPU %percentage:2%%";
      };

      # ─── Температура ─────────────────────────────────────────────────
      "module/temperature" = {
        type             = "internal/temperature";
        thermal-zone     = 0;
        warn-temperature = 80;
        interval         = 2;

        format      = "%{F#89b4fa}<ramp>%{F-} <label>";
        format-warn = "%{F#f38ba8}<ramp>%{F-} <label-warn>";

        label                  = "%temperature-c%";
        label-warn             = "%temperature-c%";
        label-warn-foreground  = "\${colors.alert}";

        ramp-0          = "";
        ramp-1          = "";
        ramp-2          = "";
        ramp-foreground = "\${colors.primary}";
      };

      # ─── Батарея (цвет по уровню) ─────────────────────────────────────
      "module/battery" = {
        type    = "internal/battery";
        battery = "BAT0";
        adapter = "ADP1";
        poll-interval = 5;

        # При заряде
        format-charging = "<animation-charging> <label-charging>";
        label-charging  = "%percentage%%";

        # При разряде — цвет меняется через format-low
        format-discharging = "<ramp-capacity> <label-discharging>";
        label-discharging  = "%percentage%%";

        format-full            = "<label-full>";
        label-full             = "%{F#a6e3a1}%{F-} Full";
        label-full-foreground  = "\${colors.success}";

        # Красный при < 15%
        format-low            = "%{F#f38ba8}<ramp-capacity>%{F-} <label-low>";
        label-low             = "%percentage%%";
        label-low-foreground  = "\${colors.alert}";
        low-at                = 15;

        ramp-capacity-0 = "";   # 0–19%
        ramp-capacity-1 = "";   # 20–39%
        ramp-capacity-2 = "";   # 40–59%  (жёлтый)
        ramp-capacity-3 = "";   # 60–79%
        ramp-capacity-4 = "";   # 80–100% (зелёный)

        ramp-capacity-0-foreground = "\${colors.alert}";
        ramp-capacity-1-foreground = "\${colors.warning}";
        ramp-capacity-2-foreground = "\${colors.warning}";
        ramp-capacity-3-foreground = "\${colors.success}";
        ramp-capacity-4-foreground = "\${colors.success}";

        animation-charging-0 = "";
        animation-charging-1 = "";
        animation-charging-2 = "";
        animation-charging-3 = "";
        animation-charging-4 = "";
        animation-charging-framerate = 750;
      };

      "settings" = {
        screenchange-reload = true;
        pseudo-transparency = true;
      };
    };
  };
}
