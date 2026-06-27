{pkgs, ...}: {
  programs.rofi = {
    enable = true;

    terminal = "${pkgs.alacritty}/bin/alacritty";
    theme = "${pkgs.rofi}/share/rofi/themes/DarkBlue.rasi";
  };
}
