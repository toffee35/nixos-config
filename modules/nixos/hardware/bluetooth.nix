{...}: {
  hardware.bluetooth = {
    enable = true;

    powerOnBoot = true;

    settings.General = {
      DisablePlugins = "sco";
      Enable = "Source,Sink,Media,Socket";
      Experimental = true;
    };
  };

  services.blueman.enable = true;
}
