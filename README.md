# nixos-config

Personal NixOS flake for `0NLaptopLegion` (Lenovo Legion 16ACH6H, Hyprland, NVIDIA RTX 3060).

## Layout

```
flake.nix                    # inputs + nixosConfigurations.laptop
disko.nix                    # LUKS + btrfs partitioning (/, /home, /nix subvolumes)
home.nix                     # top-level home-manager config (git, gh, zoxide, fzf)
hosts/laptop/                # host-specific config + hardware-configuration.nix
modules/                     # explicit imports in modules/default.nix
pkgs/                        # helper derivations (not imported as modules)
secrets/                     # encrypted credentials; see secrets/README.md
  user.nix, theme.nix        # shared user name + Tokyo Night color palette
  nix-settings.nix           # flakes, caches, gc
  hardware/                  # audio + Bluetooth, nvidia, boot (GRUB), battery, legion-rgb, quadcast-rgb, wireguard
  desktop/                   # hyprland, waybar, hyprlock, hypridle, wofi, sddm, thunar, kitty, theme-gtk, easyeffects
  development/                # docker, languages (dev toolchains/IDEs), ollama
  apps/                       # browsers, chat, media, mime defaults
  shell/                      # zsh
```

Feature modules expose `modules.<category>.<name>.enable` (usually default `true`) so pieces can be
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

## Configuration audit

See [the 2026-10-22 audit](docs/config-audit-2026-10-22.md) for verified runtime
issues, reproducibility improvements and proposed additions (in Russian).
Implementation and activation instructions: [reliability changes](docs/reliability-changes.md).

## Notable setup / things that need manual steps

- **Hyprland 0.57+** uses Home Manager's Lua configuration generator.
  `pkgs/hyprland-settings.nix` declares native Lua settings and dispatchers;
  `nix flake check` validates the generated configuration with Hyprland itself.
  The old `hyprland.conf` format is no longer supported.
  Waybar uses `ext/workspaces` to activate workspaces through the standard
  Wayland protocol. Workspaces 1–5 are persistent rules in Hyprland itself.

- **Minecraft** (`apps/minecraft.nix`): PollyMC Continued supports offline
  profiles and third-party authentication. Multiplayer requires a server that
  accepts that authentication; Microsoft/Mojang license checks still require
  ownership. Launch `pollymc-continued`, add an offline account in the setup
  wizard, then create an instance matching the server's Minecraft version.
  On NVIDIA-enabled hosts the launcher exports PRIME render-offload settings
  and selects SDL's X11 backend through XWayland. This also covers Minecraft
  26.3's SDL3 renderer, which otherwise selects AMD through native Wayland/EGL.
  `WAYLAND_DISPLAY` is unset inside the launcher so LWJGL also chooses GLX;
  mixing LWJGL's EGL loader with SDL's X11 backend prevents OpenGL startup.
  Restart the launcher after changing these settings.
  Disable with `modules.apps.minecraft.enable = false`.

- **Grok Build** (`apps/default.nix`): installs xAI's coding agent as `grok`.
  Run `grok` inside a project and sign in through the browser on first launch.
  API authentication is also supported through `XAI_API_KEY`; keep credentials
  outside the Nix configuration. Documentation: <https://docs.x.ai/build/overview>.

- **Steam** (`apps/steam.nix`): enabled through the NixOS Steam module, with
  its runtime, 32-bit graphics support and controller udev rules. In hybrid
  GPU mode, use `nvidia-offload %command%` in a game's Steam launch options
  to run that game on the RTX 3060. Disable Steam with
  `modules.apps.steam.enable = false`.

- **Native CUDA Toolkit** (`development/cuda.nix`): installs CUDA **13.2.2**
  from `cudaPackages_13_2`, matching `cu132` Python wheels and the R595 NVIDIA
  driver. Includes `nvcc`, CUDA libraries and `cuda-gdb`. `CUDA_HOME` and
  `CUDA_PATH` point at the toolkit in new login sessions. The `nvcc` wrapper
  supplies include/library paths for builds from an ordinary terminal.
  `TRITON_LIBCUDA_PATH=/run/opengl-driver/lib` lets PyPI Triton/vLLM find
  the NVIDIA driver without `/sbin/ldconfig`. For an already open terminal,
  run `export TRITON_LIBCUDA_PATH=/run/opengl-driver/lib` before starting vLLM.
  Check the compiler after applying the configuration with `nvcc --version`.
  Disable with `modules.development.cuda.enable = false`.

- **Docker files in Thunar** (`desktop/thunar.nix`): the “Файлы Docker” launcher
  and the “Docker (admin)” / “Docker volumes (admin)” sidebar bookmarks open
  `admin:///var/lib/docker` through GVfs. Enter your administrator password
  when polkit asks. `security.polkit.enablePkexecWrapper` is required on recent
  NixOS; an authentication agent alone is insufficient. File ownership and
  permissions inside Docker's storage are not changed.

- **Local AI** (`development/ollama.nix`): Ollama and Open WebUI run in Docker,
  connected over the `ollama-webui` network. Open <http://localhost:3000> and create
  the first account (it becomes the administrator). Authentication stays enabled.
  Ollama's API is available at <http://localhost:11434>; both published ports bind
  to loopback only. For remote access, forward port 3000 over SSH.
  NVIDIA Container Toolkit generates CDI configuration; only Ollama receives
  `nvidia.com/gpu=all`. Open WebUI uses the GPU through Ollama's API.
  Models live in the `ollama` volume, chats/settings in `open-webui`, and the
  signing key in `/var/lib/open-webui/secret.env` (or `/run/secrets/webui` after
  migration); preserve the key along with both volumes.
  No model is downloaded automatically. To load a model and check GPU use:

  ```bash
  docker exec -it ollama ollama pull <model>
  docker exec -it ollama ollama run <model>
  docker exec ollama ollama ps
  docker exec ollama nvidia-smi
  ```

  Disable the stack with `modules.development.ollama.enable = false` (disabling
  the Docker module also disables it). Images can be pinned via `ollamaImage`
  and `webuiImage` under that option namespace. All five containers use fixed
  image digests. To update, inspect a new image's RepoDigests, change its digest
  in Nix, build, then activate. `nix flake update` does not update Docker images.

- **NVIDIA suspend/resume** (`hardware/nvidia.nix`): `powerManagement.enable = true` is required —
  without it, resuming from lid-close sleep corrupts the DRM atomic modeset and crashes the
  Hyprland session (shows as a blank grey screen with a dead cursor).
- **CPU power policy** (`hosts/laptop/default.nix`): TLP is the sole CPU policy
  manager; auto-cpufreq is disabled. amd-pstate-epp uses dynamic `powersave`,
  with `balance_performance` and boost on AC, `balance_power` and no boost on
  battery. Audio power-saving exceptions and the charge-limit timer remain.
- **Battery charge limit** (`hardware/battery.nix`): held near **80%** (`modules.hardware.battery.limit`).
  This laptop has no `charge_control_end_threshold` — the only knob is ideapad's binary
  `conservation_mode`, whose own cap sits around 60% — so the limit is approximated: a 1-minute
  timer flips that flag on above 80% and off below 77% (`hysteresis`). Click the battery in
  waybar, or run `battery-charge-toggle`, to switch between the limit and charging to 100%; the
  mode lives in `/run`, so every boot starts capped again.
- **EasyEffects** (`desktop/easyeffects.nix`): enabled through the home-manager service, which
  installs it and runs it in the background so effects apply without the window open. No presets
  are declared in Nix on purpose — those would be read-only in the store and the GUI could not
  edit them, so `~/.config/easyeffects` stays the source of truth. RNNoise needs no extra package:
  the nixpkgs build links `librnnoise` as the built-in Noise Reduction plugin, and DeepFilterNet
  ships with it as a LADSPA plugin. Built-in speakers bypass the output pipeline:
  playback through it crackled even with the output filter bypassed, while direct
  playback was clean. `modules.desktop.easyeffects.excludedOutputDevices` controls
  this device list; the service applies it before startup without replacing presets.
  Microphone processing and processing on other output devices stay enabled.
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
- **Legion keyboard RGB** (`hardware/legion-rgb.nix`): ships its udev rule as a package named
  `60-l5p-keyboard-rgb.rules` for the same ordering reason as the microphone below — as
  `services.udev.extraRules` the `uaccess` tag was set too late to become an ACL, and the
  keyboard was root-only.
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
  service on login. A local package patch enables `QUADCASTRGB_FOREGROUND=1`;
  systemd uses `Type=simple` so the controller never forks after libusb has
  started its event thread (the forked process was stuck on a mutex without a
  USB descriptor). The mic forgets the colour whenever it loses power, and the
  controller exits when the mic stops answering. The service retries after
  200 ms (`Restart=always`, no rate limit), also restoring the colour after a replug. Manually:
  `quadcastrgb solid 4c0099` (forks into the background, `killall quadcastrgb` stops it); this
  model is a **Quadcast 2S** (`03f0:02b5`), which upstream drives in `solid` mode only.
- **SDDM astronaut theme** (`desktop/sddm.nix`): `UseRealName` is overridden off via the
  package's `themeConfig`, so the login field shows the actual username instead of the account's
  GECOS description.
- **Keyboard layout in the bar** (`desktop/waybar.nix`): waybar's own `hyprland/language` module
  cannot read this laptop's keyboard. It locates the device/layout boundary in the event by the
  last `(`, and the device is called `ite-device(8910)-keyboard`, so the layout is parsed out of
  the wrong place — it worked for `English (US)` only because that name happens to contain a
  parenthesis too, and `Russian` came out blank. Replaced by `custom/language`, a script that
  matches the device exactly and streams Hyprland's event socket. Labels are configurable via
  `modules.desktop.waybar.languageLabels`; the keyboard is resolved at runtime (`main: true`)
  instead of being hardcoded.
- **Monitors** (`desktop/hyprland.nix`): `modules.desktop.hyprland.monitors`, a list of Hyprland
  `name,resolution@refresh,position,scale` lines. Defaults to every output at its preferred mode.
- **Screenshots** (`desktop/hyprland.nix`): `Print` = full screen, `SUPER+Print` = region select
  (screen freezes via `hyprpicker -rz` during selection, like grimblast's `--freeze`). Saved to
  `~/Pictures`.
- **Hide a window from screen share**: `SUPER+SHIFT+H` toggles Hyprland's native
  `no_screen_share` rule on the focused window.

## Adding a new module

Copy the shape of an existing one under `modules/<category>/`, add an `enable` option and wrap
`config` in `mkIf cfg.enable`. Nothing has to be registered: `modules/default.nix` imports every
`.nix` file under `modules/` recursively.
