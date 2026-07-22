{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.apps;
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
        telegram-desktop
        discord
        obsidian
        obs-studio
        ffmpeg
        zoom-us
        vlc
        lutris
        opencode
        claude-code
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
