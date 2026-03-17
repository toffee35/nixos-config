{pkgs, ...}: {
  programs.lutris = {
    enable = true;

    extraPackages = [
      pkgs.winetricks
    ];

    protonPackages = [
      pkgs.proton-ge-bin
    ];

    winePackages = [
      pkgs.wineWow64Packages.full
    ];
  };
}
