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
  ];
}
