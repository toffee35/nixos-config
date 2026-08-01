{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.theme-gtk;
in {
  options.modules.desktop.theme-gtk = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable GTK/Qt dark theming, cursor, and system fonts";
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.modules.user.name} = {
      # GTK Dark Theme Configuration
      gtk = {
        enable = true;
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        iconTheme = {
          name = "Tela-circle-dark";
          package = pkgs.tela-circle-icon-theme;
        };
      };

      # Qt Theme Configuration
      qt = {
        enable = true;
        platformTheme.name = "gtk3";
        style.name = "adwaita-dark";
      };

      # Cursor theme
      home.pointerCursor = {
        enable = true;
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
        size = 24;
        gtk.enable = true;
      };
    };

    # System-level fonts required for desktop rendering
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];

    # Enable fontconfig default fonts for proper emoji and fallback rendering
    fonts.fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
