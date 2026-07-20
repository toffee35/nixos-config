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
    programs.nix-ld.enable = true;

    home-manager.users.${config.modules.user.name} = {
      home.packages = with pkgs; [
        google-chrome
        chromium
        telegram-desktop
        obsidian
        obs-studio
        ffmpeg
        zoom-us
        vlc
        lutris
        opencode
        hmcl
      ];

      # Configure MIME associations to open video and audio with VLC by default
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
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
