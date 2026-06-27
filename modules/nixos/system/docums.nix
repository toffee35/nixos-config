{...}: {
  documentation = {
    enable = false;

    nixos.enable = false;

    man = {
      enable = false;
      mandoc.enable = false;
      man-db.enable = false;
    };

    info.enable = false;

    doc.enable = false;

    dev.enable = false;
  };
}
