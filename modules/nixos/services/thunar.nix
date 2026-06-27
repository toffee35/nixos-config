{pkgs, ...}: {
  programs.thunar = {
    enable = true;

    plugins = with pkgs; [
      thunar-volman
      thunar-archive-plugin
      thunar-media-tags-plugin
    ];
  };

  programs.xfconf.enable = true;

  services = {
    gvfs.enable = true;
    tumbler.enable = true;
  };

  environment.systemPackages = with pkgs; [
    file-roller
    ffmpegthumbnailer
  ];
}
