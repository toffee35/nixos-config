{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.thunar;
in {
  options.modules.desktop.thunar = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Thunar file manager";
    };
  };

  config = mkIf cfg.enable {
    programs.thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    # thunar-archive-plugin above only adds the "Extract here" / "Create
    # archive" menu entries; it hands the actual work to an external archiver,
    # and none was installed, so the entries had nothing to call. xarchiver in
    # turn shells out to the format tools, hence zip/unzip/7z alongside it.
    environment.systemPackages = with pkgs; [
      xarchiver
      zip
      unzip
      p7zip
    ];

    services.gvfs.enable = true;

    services.tumbler.enable = true;

    home-manager.users.${config.modules.user.name} = {
      # Nothing in the session could ever ask for a password: polkit itself was
      # enabled, but no authentication agent ran, so any privileged request just
      # failed silently. That is also what kept gvfs's admin:// backend from
      # mounting, which is how Thunar reaches files as root — it asks polkit,
      # and polkit needs an agent to show the prompt.
      #
      # hyprpolkitagent is the one Hyprland ships for this. A user service tied
      # to the session rather than an exec-once, so systemd restarts it if it
      # dies.
      systemd.user.services.hyprpolkitagent = {
        Unit = {
          Description = "Polkit authentication agent";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # Bind shortcut only if Hyprland is also enabled
      wayland.windowManager.hyprland.settings.bind = mkIf config.modules.desktop.hyprland.enable [
        "$mod, E, exec, thunar"
      ];
    };
  };
}
