{pkgs, config, ...}: {
  gtk = {
    enable = true;

    gtk4.theme = config.gtk.theme;

    cursorTheme = {
      name = "Quintom_Ink";
      package = pkgs.quintom-cursor-theme;
    };

    iconTheme = {
      name = "Colloid-Dark";
      package = pkgs.colloid-icon-theme;
    };

    theme = {
      name = "Jasper-Dark";
      package = pkgs.jasper-gtk-theme;
    };
  };

  qt = {
    enable = true;

    platformTheme.name = "gtk";

    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };
}
