{pkgs, ...}: {
  nixpkgs.overlays = [
    (final: prev: {
      openldap = prev.openldap.overrideAttrs (oldAttrs: {
        doCheck = false;
      });
    })
  ];

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
