{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.apps;

  # Runs a program inside a systemd scope with a soft memory cap, by replacing
  # the binaries in the profile rather than wrapping the autostart line: a cap
  # in hyprland's exec-once would be bypassed by wofi, by the .desktop entry
  # and by launching from a terminal. The .desktop files call these by name
  # (Exec=Discord, Exec=Telegram), so all paths go through the cap.
  #
  # MemoryHigh throttles instead of killing: above the limit the kernel
  # reclaims the app's idle pages into zram. MemoryMax would kill it instead.
  capMemory = { pkg, bins, high }:
    pkgs.symlinkJoin {
      name = "${pkg.pname or pkg.name}-capped";
      paths = [ pkg ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = lib.concatMapStrings (b: ''
        rm -f $out/bin/${b}
        makeWrapper ${pkgs.systemd}/bin/systemd-run $out/bin/${b} \
          --add-flags "--user --scope --collect --property=MemoryHigh=${high}" \
          --add-flags "${pkg}/bin/${b}"
      '') bins;
    };
in {
  options.modules.apps = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable standard user applications and nix-ld";
    };
  };

  config = mkIf cfg.enable {
    # Enable nix-ld to run unpatched dynamic binaries (important for precompiled CLI tools, etc.)
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        # Nvidia driver userspace libs (libcuda.so.1 etc.) - lets unpatched binaries
        # (e.g. pip/uv-installed PyTorch wheels) find CUDA without manual LD_LIBRARY_PATH.
        # Kept in sync with the driver package used in modules/hardware/nvidia.nix.
        config.boot.kernelPackages.nvidiaPackages.stable
        zlib
        fuse3
        alsa-lib
        at-spi2-atk
        atk
        cairo
        cups
        dbus
        expat
        fontconfig
        freetype
        gdk-pixbuf
        glib
        gtk3
        libGL
        libappindicator-gtk3
        libdrm
        libnotify
        libpulseaudio
        libuuid
        libusb1
        libice
        libsm
        libx11
        libxscrnsaver
        libxcomposite
        libxcursor
        libxdamage
        libxext
        libxfixes
        libxi
        libxrandr
        libxrender
        libxtst
        libxcb
        libxshmfence
        libxkbfile
        libxxf86vm
        libxkbcommon
        openssl
        systemd
      ];
    };

    home-manager.users.${config.modules.user.name} = {
      home.packages = with pkgs; [
        google-chrome
        chromium
        (capMemory { pkg = telegram-desktop; bins = [ "Telegram" ]; high = "600M"; })
        # Measured by PSS, Discord sat on 1347 MB, most of it idle, so it is
        # capped like Telegram above.
        #
        # The XWayland experiment that used to live here is gone: it unset
        # NIXOS_OZONE_WL to test whether Wayland caused the September crashes,
        # but it never took effect — the renderer still ran with
        # --ozone-platform=wayland, because Electron picks Wayland on its own.
        # So it proved nothing and only added a layer.
        (capMemory { pkg = discord; bins = [ "discord" "Discord" ]; high = "900M"; })
        obsidian
        obs-studio
        ffmpeg
        zoom-us
        vlc
        lutris
        opencode
        claude-code
        codex
        chatgpt
        hmcl
        imv
        xdg-utils
      ];

      home.sessionVariables = {
        BROWSER = "google-chrome";
        EDITOR = "zeditor --wait";
        VISUAL = "zeditor";
        TERMINAL = "kitty";
      };

      # Automatically manage and create standard XDG user directories (Downloads, Documents, etc.)
      xdg.userDirs = {
        enable = true;
        createDirectories = true;
      };

      # Configure default applications for various MIME types
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          # Web & Documents
          "text/html" = "google-chrome.desktop";
          "text/xml" = "google-chrome.desktop";
          "x-scheme-handler/http" = "google-chrome.desktop";
          "x-scheme-handler/https" = "google-chrome.desktop";
          "x-scheme-handler/about" = "google-chrome.desktop";
          "x-scheme-handler/unknown" = "google-chrome.desktop";
          "application/pdf" = "google-chrome.desktop";

          # File Manager
          "inode/directory" = "thunar.desktop";

          # Text & Code Editing
          "text/plain" = "zed.desktop";
          "text/markdown" = "zed.desktop";
          "application/json" = "zed.desktop";

          # Images
          "image/png" = "imv.desktop";
          "image/jpeg" = "imv.desktop";
          "image/gif" = "imv.desktop";
          "image/webp" = "imv.desktop";

          # Video & Audio
          "video/mp4" = "vlc.desktop";
          "video/mpeg" = "vlc.desktop";
          "video/quicktime" = "vlc.desktop";
          "video/x-matroska" = "vlc.desktop";
          "audio/mpeg" = "vlc.desktop";
          "audio/ogg" = "vlc.desktop";
          "audio/wav" = "vlc.desktop";
        };
      };
    };
  };
}
