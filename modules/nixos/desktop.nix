{ pkgs, ... }: {
  services.xserver = {
    enable = true;
    dpi = 90;
    xkb = {
      layout = "us,ru";
      options = "grp:alt_shift_toggle";
    };

    windowManager.bspwm.enable = true;
  };

  services.displayManager.sddm = {
    enable = true;
    autoNumlock = true;
    package = pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";
    extraPackages = with pkgs; [
      sddm-astronaut
      qt6.qtmultimedia
    ];
  };
}
