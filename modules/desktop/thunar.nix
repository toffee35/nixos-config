{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.desktop.thunar;
  dockerBookmarks = pkgs.writeShellScript "thunar-docker-bookmarks" ''
    set -eu
    config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0"
    ${pkgs.coreutils}/bin/mkdir -p "$config_dir"
    bookmarks="$config_dir/bookmarks"
    ${pkgs.coreutils}/bin/touch "$bookmarks"
    if [ -s "$bookmarks" ] && [ -n "$(${pkgs.coreutils}/bin/tail -c 1 "$bookmarks")" ]; then
      printf '\n' >> "$bookmarks"
    fi

    # Keep bookmarks editable in Thunar and preserve the user's other entries.
    for entry in \
      'admin:///var/lib/docker Docker (admin)' \
      'admin:///var/lib/docker/volumes Docker volumes (admin)'; do
      uri="''${entry%% *}"
      if ! ${pkgs.gnugrep}/bin/grep -Eq "^$uri( |$)" "$bookmarks"; then
        printf '%s\n' "$entry" >> "$bookmarks"
      fi
    done
  '';
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

    # Polkit's agent alone is not enough: recent NixOS defaults leave the
    # setuid pkexec wrapper disabled. GVfs admin:// needs that wrapper.
    security.polkit = {
      enable = true;
      enablePkexecWrapper = true;
    };

    services.tumbler.enable = true;

    home-manager.users.${config.modules.user.name} = { lib, ... }: {
      # GVfs elevates file operations through polkit; Thunar itself stays in
      # the user's session. Docker's on-disk ownership and modes stay intact.
      home.activation.dockerBookmarks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${dockerBookmarks}
      '';

      xdg.desktopEntries.docker-files = {
        name = "Файлы Docker";
        comment = "Открыть хранилище Docker с правами администратора";
        exec = "${config.programs.thunar.finalPackage}/bin/thunar admin:///var/lib/docker";
        icon = "folder-system";
        terminal = false;
        categories = [ "System" "FileManager" ];
      };

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
        { _args = [ "SUPER + E" (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("thunar")'') ]; }
      ];
    };
  };
}
