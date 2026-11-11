{ lib, monitors }:
let
  lua = lib.generators.mkLuaInline;
  bind = key: action: {
    _args = [
      key
      (lua action)
    ];
  };
  exec = key: command: bind key "hl.dsp.exec_cmd(${builtins.toJSON command})";
  media = key: command: {
    _args = [
      key
      (lua "hl.dsp.exec_cmd(${builtins.toJSON command})")
      {
        locked = true;
        repeating = true;
      }
    ];
  };
  directions = {
    left = {
      x = -20;
      y = 0;
    };
    right = {
      x = 20;
      y = 0;
    };
    up = {
      x = 0;
      y = -20;
    };
    down = {
      x = 0;
      y = 20;
    };
  };
in
{
  workspace_rule = map (id: {
    workspace = toString id;
    persistent = true;
  }) (lib.range 1 5);
  config = {
    input = {
      kb_layout = "us,ru";
      kb_options = "grp:alt_shift_toggle";
      follow_mouse = 1;
      touchpad.natural_scroll = true;
    };
    general = {
      gaps_in = 2;
      gaps_out = 4;
      border_size = 1;
      col.active_border = "rgba(ffffff66)";
      col.inactive_border = "rgba(ffffff00)";
      layout = "dwindle";
    };
    decoration = {
      rounding = 3;
      blur = {
        enabled = true;
        size = 3;
        passes = 1;
      };
    };
    animations.enabled = true;
    ecosystem.no_update_news = true;
  };
  monitor = map (
    text:
    let
      fields = lib.splitString "," text;
      # Fields past the fourth are "key=value" options, e.g. "cm=srgb".
      # Numbers and booleans are parsed, anything else stays a string.
      extra = lib.listToAttrs (map (
        field:
        let
          kv = lib.splitString "=" field;
          value = lib.concatStringsSep "=" (lib.drop 1 kv);
          literal = builtins.match "-?[0-9]+(\\.[0-9]+)?|true|false" value != null;
        in
        lib.nameValuePair (builtins.head kv) (if literal then builtins.fromJSON value else value)
      ) (lib.drop 4 fields));
    in
    {
      output = builtins.elemAt fields 0;
      mode = builtins.elemAt fields 1;
      position = builtins.elemAt fields 2;
      scale =
        let
          scale = builtins.elemAt fields 3;
        in
        if scale == "auto" then scale else builtins.fromJSON scale;
      # Hyprland turns on wide color gamut for panels that report it but keeps
      # an 8-bit XRGB8888 framebuffer, and warns about the mismatch. Outputs
      # without 10-bit support fall back to 8-bit.
      bitdepth = 10;
    }
    // extra
  ) monitors;
  curve = {
    _args = [
      "myBezier"
      {
        type = "bezier";
        points = [
          [
            0.05
            0.9
          ]
          [
            0.1
            1.0
          ]
        ];
      }
    ];
  };
  animation = [
    {
      leaf = "windows";
      enabled = true;
      speed = 2;
      bezier = "myBezier";
    }
    {
      leaf = "windowsOut";
      enabled = true;
      speed = 1;
      bezier = "myBezier";
      style = "popin 80%";
    }
    {
      leaf = "border";
      enabled = true;
      speed = 2;
      bezier = "default";
    }
    {
      leaf = "fade";
      enabled = true;
      speed = 1;
      bezier = "default";
    }
    {
      leaf = "workspaces";
      enabled = true;
      speed = 2;
      bezier = "myBezier";
    }
  ];
  window_rule = [
    {
      name = "pycharm-workspace";
      match.class = "jetbrains-pycharm";
      workspace = "1";
    }
    {
      name = "chrome-workspace";
      match.class = "google-chrome";
      workspace = "2 silent";
    }
    {
      name = "discord-workspace";
      match.class = "(discord|Discord)";
      workspace = "3 silent";
    }
    {
      name = "easyeffects-workspace";
      match.class = "com.github.wwmm.easyeffects";
      workspace = "5 silent";
    }
    {
      name = "picture-in-picture";
      match.title = "(Picture-in-Picture|Picture in picture)";
      float = true;
      pin = true;
      keep_aspect_ratio = true;
    }
  ];
  bind = [
    (exec "SUPER + Return" "kitty")
    (bind "SUPER + Q" "hl.dsp.window.close()")
    (exec "SUPER + R" "wofi --show drun")
    (exec "SUPER + D" "wofi --show drun")
    (exec "SUPER + SPACE" "wofi --show drun")
    (exec "SUPER + L" "hyprlock")
    (bind "SUPER + S" ''hl.dsp.window.pin({action="toggle"})'')
    (bind "SUPER + SHIFT + H" ''hl.dsp.window.set_prop({prop="no_screen_share",value="toggle"})'')
    (exec "XF86TouchpadToggle" "touchpad-toggle")
    (exec "Print" "screenshot-full")
    (exec "SUPER + Print" "screenshot-region")
    (bind "SUPER + F" ''hl.dsp.window.float({action="toggle"})'')
    (bind "SUPER + SHIFT + F" "hl.dsp.window.fullscreen()")
    (media "XF86AudioLowerVolume" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
    (media "XF86AudioRaiseVolume" "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+")
    (media "XF86MonBrightnessDown" "brightnessctl set 5%-")
    (media "XF86MonBrightnessUp" "brightnessctl set +5%")
    {
      _args = [
        "XF86AudioMute"
        (lua ''hl.dsp.exec_cmd("mute-all")'')
        { locked = true; }
      ];
    }
    {
      _args = [
        "XF86AudioMicMute"
        (lua ''hl.dsp.exec_cmd("mic-toggle")'')
        { locked = true; }
      ];
    }
    {
      _args = [
        "SUPER + mouse:272"
        (lua "hl.dsp.window.drag()")
        { mouse = true; }
      ];
    }
    {
      _args = [
        "SUPER + mouse:273"
        (lua "hl.dsp.window.resize()")
        { mouse = true; }
      ];
    }
  ]
  ++ lib.concatMap (
    i:
    let
      number = toString i;
    in
    [
      (bind "SUPER + ${number}" "hl.dsp.focus({workspace=${number}})")
      (bind "SUPER + SHIFT + ${number}" "hl.dsp.window.move({workspace=${number},follow=false})")
      (bind "SUPER + CONTROL + ${number}" "hl.dsp.window.move({workspace=${number},follow=false})")
    ]
  ) (lib.range 1 8)
  ++ lib.concatLists (
    lib.mapAttrsToList (direction: delta: [
      (bind "SUPER + ${direction}" ''hl.dsp.focus({direction="${direction}"})'')
      (bind "SUPER + SHIFT + ${direction}" ''hl.dsp.window.move({direction="${direction}"})'')
      {
        _args = [
          "SUPER + CONTROL + ${direction}"
          (lua "hl.dsp.window.resize({x=${toString delta.x},y=${toString delta.y},relative=true})")
          { repeating = true; }
        ];
      }
    ]) directions
  );
}
