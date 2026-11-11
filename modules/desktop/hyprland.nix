{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.hyprland;
  palette = config.modules.theme.palette;


  # Every capture node, not just the default one. The default source is
  # EasyEffects' virtual easyeffects_source, which Discord records from, while
  # EasyEffects itself reads the QuadCast directly — so muting only the
  # default left the physical mic live and its level meter moving, and read as
  # "the mic ignores the key". It also let the two drift apart: the QuadCast
  # was found sitting muted on its own. Driving them all to one state fixes
  # both.
  set-all-sources = pkgs.writeShellScript "set-all-sources" ''
    state="$1"
    ${pkgs.pipewire}/bin/pw-dump \
      | ${pkgs.jq}/bin/jq -r '.[]
          | select(.type == "PipeWire:Interface:Node")
          | select((.info.props["media.class"] // "") | startswith("Audio/Source"))
          | .id' \
      | while read -r id; do
          ${pkgs.wireplumber}/bin/wpctl set-mute "$id" "$state"
        done
  '';

  # Fn+F4. The key and the binding were fine all along; see set-all-sources
  # for why it looked broken. Also notifies, since neither the QuadCast LED
  # (hardware mute only) nor Discord shows the software state.
  mic-toggle = pkgs.writeShellScriptBin "mic-toggle" ''
    if ${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | ${pkgs.gnugrep}/bin/grep -q MUTED; then
      ${set-all-sources} 0
      ${pkgs.libnotify}/bin/notify-send -t 1500 -a "System" "Microphone" "Unmuted"
    else
      ${set-all-sources} 1
      ${pkgs.libnotify}/bin/notify-send -t 1500 -a "System" "Microphone" "Muted"
    fi
  '';

  # Fn+F1: toggle the speakers, then drive every mic to the same state, so one
  # key always yields one consistent state instead of two that drift apart.
  mute-all = pkgs.writeShellScriptBin "mute-all" ''
    ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

    if ${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ | ${pkgs.gnugrep}/bin/grep -q MUTED; then
      ${set-all-sources} 1
      ${pkgs.libnotify}/bin/notify-send -t 1500 -a "System" "Audio" "Speakers and microphone muted"
    else
      ${set-all-sources} 0
      ${pkgs.libnotify}/bin/notify-send -t 1500 -a "System" "Audio" "Speakers and microphone on"
    fi
  '';

  # The whole PipeWire session has twice got stuck: no playback started on any
  # device, formats renegotiated in a loop, and only restarting the session
  # manager brought it back. The cause is still unknown, so this is the cure,
  # not a fix: it restarts WirePlumber and nothing else -- no mute, codec or
  # profile is touched, so whatever state the devices were put in by hand stays.
  sound-restart = pkgs.writeShellScriptBin "sound-restart" ''
    systemctl --user restart wireplumber
    ${pkgs.libnotify}/bin/notify-send -t 2000 -a "System" "Audio" "WirePlumber restarted"
  '';

  touchpad-toggle = pkgs.writeShellScriptBin "touchpad-toggle" ''
    DEVICE=$(${pkgs.hyprland}/bin/hyprctl devices -j | ${pkgs.jq}/bin/jq -r '.mice[] | select(.name | ascii_downcase | contains("touchpad")) | .name' | head -n 1)

    if [ -z "$DEVICE" ]; then
      ${pkgs.libnotify}/bin/notify-send -t 1500 -a "System" "Touchpad" "No touchpad device found"
      exit 1
    fi

    STATE_FILE="$XDG_RUNTIME_DIR/touchpad_state"
    if [ ! -f "$STATE_FILE" ]; then
      echo "enabled" > "$STATE_FILE"
    fi

    CURRENT_STATE=$(cat "$STATE_FILE")
    DEVICE_LUA=$(printf '%s' "$DEVICE" | ${pkgs.jq}/bin/jq -Rs .)

    if [ "$CURRENT_STATE" = "enabled" ]; then
      ${pkgs.hyprland}/bin/hyprctl eval "hl.device({name=$DEVICE_LUA,enabled=false})"
      echo "disabled" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send -t 1500 -a "System" "Touchpad" "Disabled"
    else
      ${pkgs.hyprland}/bin/hyprctl eval "hl.device({name=$DEVICE_LUA,enabled=true})"
      echo "enabled" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send -t 1500 -a "System" "Touchpad" "Enabled"
    fi
  '';

  screenshot-full = pkgs.writeShellScriptBin "screenshot-full" ''
    mkdir -p "$HOME/Pictures"
    FILE="$HOME/Pictures/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
    ${pkgs.grim}/bin/grim "$FILE"
    ${pkgs.libnotify}/bin/notify-send -t 1500 -a "Screenshot" "Screenshot saved" "$FILE"
  '';

  screenshot-region = pkgs.writeShellScriptBin "screenshot-region" ''
    mkdir -p "$HOME/Pictures"

    # Freeze the screen (render-inactive, no zoom lens) so the selection isn't
    # made against a live/changing view, matching grimblast's --freeze behavior.
    ${pkgs.hyprpicker}/bin/hyprpicker -rz &
    PICKER_PID=$!
    sleep 0.2

    GEOM=$(${pkgs.slurp}/bin/slurp)

    kill "$PICKER_PID" 2>/dev/null

    [ -z "$GEOM" ] && exit 0
    FILE="$HOME/Pictures/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
    ${pkgs.grim}/bin/grim -g "$GEOM" "$FILE"
    ${pkgs.libnotify}/bin/notify-send -t 1500 -a "Screenshot" "Screenshot saved" "$FILE"
  '';
in {
  options.modules.desktop.hyprland = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Hyprland window manager";
    };

    monitors = mkOption {
      type = types.listOf types.str;
      default = [ ",preferred,auto,1" ];
      example = [ "eDP-1,2560x1600@165,0x0,1" "HDMI-A-1,preferred,auto,1" ];
      description = ''
        Hyprland monitor lines, "name,resolution@refresh,position,scale",
        optionally followed by "key=value" fields such as "cm=srgb".
        The default catches every output with its preferred mode, unscaled.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    environment.sessionVariables = {
      # This is the name the nixpkgs wrappers actually read. The previous
      # NIXOS_OZONE_GFX_PROVIDER is not a nixpkgs variable at all — nothing in
      # the store looks at it — so Electron apps were started without their
      # Wayland flags, which is why Discord's screen share found nothing to
      # capture through the portal.
      NIXOS_OZONE_WL = "1";
    };

    home-manager.users.${config.modules.user.name} = {
      # A system switch can restart PipeWire after the portals, leaving their
      # capture connection stale. Restart them with PipeWire, after it is ready.
      xdg.configFile = genAttrs [
        "systemd/user/xdg-desktop-portal.service.d/pipewire.conf"
        "systemd/user/xdg-desktop-portal-hyprland.service.d/pipewire.conf"
      ] (_: {
        text = ''
          [Unit]
          Requires=pipewire.service
          After=pipewire.service
          PartOf=pipewire.service
        '';
      });

      # Wayland utilities
      home.packages = with pkgs; [
        pavucontrol
        wl-clipboard
        libnotify
        mako
        fastfetch
        btop
        touchpad-toggle
        mute-all
        mic-toggle
        sound-restart
        brightnessctl
        grim
        slurp
        hyprpicker
        screenshot-full
        screenshot-region
      ];

      # Hyprpaper Wallpaper Service
      # Hyprland configuration
      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";
        importantPrefixes = [ "config" "curve" "monitor" ];
        settings = import ../../pkgs/hyprland-settings.nix {
          inherit lib;
          monitors = cfg.monitors;
        };
        extraConfig = ''
          hl.on("hyprland.start", function()
            hl.exec_cmd("mako")
            hl.exec_cmd("[workspace 1] pycharm")
            hl.exec_cmd("[workspace 2 silent] google-chrome")
            hl.exec_cmd("[workspace 3 silent] Discord")
          end)
        '';
      };
    };
  };
}
