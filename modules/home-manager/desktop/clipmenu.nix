{pkgs, ...}: {
  services.clipmenu = {
    enable = true;

    launcher = "rofi";
  };

  home.packages = [pkgs.xclip];
}
