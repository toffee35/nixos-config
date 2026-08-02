# nixos-config

Personal NixOS flake for `0NLaptopLegion` (Lenovo Legion 16ACH6H, Hyprland, NVIDIA RTX 3060).

## Layout

```
flake.nix                    # inputs + nixosConfigurations.laptop
disko.nix                    # LUKS + btrfs partitioning (/, /home, /nix subvolumes)
home.nix                     # top-level home-manager config (git, gh, zoxide, fzf)
hosts/laptop/                # host-specific config + hardware-configuration.nix
modules/                     # auto-imported by modules/default.nix
  user.nix, theme.nix        # shared user name + Tokyo Night color palette
  nix-settings.nix           # flakes, caches, gc
  hardware/                  # nvidia, boot (GRUB), legion-rgb, quadcast-rgb, wireguard, android-mic
  desktop/                   # hyprland, waybar, hyprlock, hypridle, wofi, sddm, thunar, kitty, theme-gtk
  development/                # docker, languages (dev toolchains/IDEs), ollama
  apps/                       # browsers, chat, media, mime defaults
  shell/                      # zsh
```

Every module exposes `modules.<category>.<name>.enable` (default `true`) so any piece can be
turned off per-host without deleting code, e.g.:

```nix
modules.development.docker.enable = false;
```

## Usage

```bash
# check the current diff builds cleanly
sudo nixos-rebuild dry-build --flake .#laptop

# build without activating (safe to run anytime)
sudo nixos-rebuild build --flake .#laptop

# apply
sudo nixos-rebuild switch --flake .#laptop
```

## Notable setup / things that need manual steps

- **NVIDIA suspend/resume** (`hardware/nvidia.nix`): `powerManagement.enable = true` is required —
  without it, resuming from lid-close sleep corrupts the DRM atomic modeset and crashes the
  Hyprland session (shows as a blank grey screen with a dead cursor).
- **auto-cpufreq** (`hosts/laptop/default.nix`): governor follows AC/battery automatically. To
  override manually (e.g. force performance while on battery), use
  `sudo auto-cpufreq --force=performance|powersave|reset` — it persists until reset instead of
  being silently reverted on the next poll.
- **Battery conservation mode**: capped at 60-80% charge by default at every boot. Toggle to
  100%-charge mode without sudo with `battery-conservation-toggle`.
- **WireGuard** (`hardware/wireguard.nix`): LAN-only VPN server on `wg0` (`10.100.0.1/24`,
  `51820/udp`), trusted for full host access once connected. The server's private key is **not**
  in this repo (it's public on GitHub) — generate it on the machine, outside git:
  ```bash
  sudo install -d -m 700 /etc/wireguard
  wg genkey | sudo tee /etc/wireguard/private.key > /dev/null
  sudo chmod 600 /etc/wireguard/private.key
  ```
  Add new client peers under `peers` in `modules/hardware/wireguard.nix` (public keys only —
  not sensitive). Docker's Portainer/Transmission admin UIs are bound to `127.0.0.1` and
  `10.100.0.1` specifically (not `0.0.0.0`) since Docker's own iptables rules bypass the NixOS
  firewall for published ports.
- **HyperX Quadcast RGB** (`hardware/quadcast-rgb.nix`): thin wrapper over the `quadcastrgb`
  flake input, which is **our own fork** ([toffee35/QuadcastRGB](https://github.com/toffee35/QuadcastRGB),
  branch `flake-and-qs2s-fix`) because two things are still pending upstream:
  [PR #33](https://github.com/Ors1mer/QuadcastRGB/pull/33) adds the flake + NixOS module, and
  [PR #32](https://github.com/Ors1mer/QuadcastRGB/pull/32) fixes the Quadcast 2S — this mic
  acknowledges the colour packets in a form upstream rejects, so without it the daemon quits
  before lighting anything. **Point the input back at `github:Ors1mer/QuadcastRGB` once both are
  merged.** The module's udev rule lands in `60-quadcastrgb.rules`, which must sort before
  systemd's `73-seat-late.rules` — that is the rule turning `TAG+="uaccess"` into an actual ACL,
  so a rule numbered 99 (what `services.udev.extraRules` produces) is silently too late and
  leaves the mic root-only. `services.quadcastrgb.arguments` sets the lights via a systemd user
  service on login; the mic forgets them whenever it loses power. Manually:
  `quadcastrgb solid 4c0099` (forks into the background, `killall quadcastrgb` stops it); this
  model is a **Quadcast 2S** (`03f0:02b5`), which upstream drives in `solid` mode only.
- **Android phone as mic** (`hardware/android-mic.nix`): installs `adb` + `audiosource`
  ([gdzx/audiosource](https://github.com/gdzx/audiosource)). Connect via USB, run
  `audiosource run`, approve the mic permission on the phone.
- **SDDM astronaut theme** (`desktop/sddm.nix`): `UseRealName` is overridden off via the
  package's `themeConfig`, so the login field shows the actual username instead of the account's
  GECOS description.
- **Screenshots** (`desktop/hyprland.nix`): `Print` = full screen, `SUPER+Print` = region select
  (screen freezes via `hyprpicker -rz` during selection, like grimblast's `--freeze`). Saved to
  `~/Pictures`.
- **Hide a window from screen share**: `SUPER+SHIFT+H` toggles Hyprland's native
  `no_screen_share` rule on the focused window.

## Adding a new module

Copy the shape of an existing one under `modules/<category>/`, add an `enable` option, wrap
`config` in `mkIf cfg.enable`, then list the file in `modules/default.nix`'s `imports`.
