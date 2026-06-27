{...}: {
  boot = {
    loader = {
      grub = {
        efiSupport = true;
        device = "nodev";

        splashImage = null;
      };

      timeout = 2;

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
  };
}
