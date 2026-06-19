{
  nixList,
  pkgs,
  ...
}: {
  imports = nixList ./.;

  home.packages = with pkgs; [
    gcc
    libcap
    pkg-config
    openssl
    sqlite
    just
    gnumake
    gtk3
    webkitgtk_4_1
    glib

    antigravity
    opencode-desktop
  ];
}
