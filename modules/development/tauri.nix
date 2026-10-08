{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.development.tauri;
  user = config.modules.user.name;

  # Only the `dev` outputs go into the profile. Those carry the headers and
  # the .pc files — the equivalent of Debian's -dev packages — and each .pc
  # already points at the matching runtime store path, so compilation and
  # linking resolve without the runtime halves being installed too.
  #
  # Installing the runtime outputs as well breaks the profile outright:
  # librsvg and gdk-pixbuf both ship lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
  # and buildEnv refuses the collision.
  libs = with pkgs; [
    webkitgtk_4_1      # libwebkit2gtk-4.1-dev
    openssl            # libssl-dev
    libayatana-appindicator  # libayatana-appindicator3-dev
    librsvg            # librsvg2-dev
    libsoup_3
    gtk3
    glib
    cairo
    gdk-pixbuf
    atk

    # Pulled in transitively on Debian, but here every .pc in the Requires
    # chain has to be present in the profile itself: gdk-3.0 asks for pango,
    # pango for harfbuzz and fribidi, gtk3 for the at-spi2 pair and libepoxy,
    # and webkit for javascriptcoregtk.
    pango
    harfbuzz
    fribidi
    at-spi2-atk
    at-spi2-core
    libepoxy
    libxkbcommon
    wayland
    zlib
    libayatana-indicator
    ayatana-ido
    # Only the glib half: libdbusmenu and libdbusmenu-gtk3 are both
    # single-output and ship the same Dbusmenu-0.4.typelib, which buildEnv
    # refuses. ayatana-appindicator3-0.1.pc asks for dbusmenu-glib-0.4.
    libdbusmenu
    dbus
    libx11
    libxtst
    libxi
    libxcursor
    libxrandr
    libxinerama
    # xproto.pc, recordproto.pc and the rest of the Requires of libX11/libXtst.
    # lowPrio because xorgproto and libX11's dev output both ship
    # include/X11/extensions/XKBgeom.h; this lets buildEnv take libX11's copy
    # instead of refusing the collision.
    (lib.lowPrio xorgproto)
  ];
in {
  options.modules.development.tauri = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install the Tauri build dependencies into the user profile";
    };
  };

  config = mkIf cfg.enable {
    # Profiles link only a fixed set of subdirectories, and share/pkgconfig is
    # not among them by default — so zlib.pc, which lives there rather than in
    # lib/pkgconfig, never appeared and every module requiring zlib failed to
    # resolve.
    environment.pathsToLink = [ "/share/pkgconfig" ];

    home-manager.users.${user} = {
      home.packages =
        # Not every library is multi-output; single-output ones carry their .pc
        # in the one output they have.
        map (p: p.dev or p) libs
        ++ (with pkgs; [
          pkg-config
          gcc
          gnumake          # build-essential
          xdotool          # libxdo-dev
          file
          curl
          wget
        ]);

      # Without this pkg-config finds nothing: it does not look inside the
      # profile on its own, and nixpkgs normally sets this per build rather
      # than globally. Points at the aggregated profile, so it keeps working
      # as packages are added or removed.
      home.sessionVariables = {
        PKG_CONFIG_PATH = "/etc/profiles/per-user/${user}/lib/pkgconfig:/etc/profiles/per-user/${user}/share/pkgconfig";
      };
    };
  };
}
