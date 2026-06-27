{pkgs, ...}: {
  hardware.graphics.extraPackages = with pkgs; [
    intel-vaapi-driver
    intel-media-driver
    intel-va-driver
    libvdpau-va-gl
  ];
}
