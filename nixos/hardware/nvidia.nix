{
  config,
  lib,
  ...
}: {
  services.xserver.videoDrivers = ["nvidia"];

  nixpkgs.config.nvidia.acceptLicense = true;

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      forceFullCompositionPipeline = true;

      powerManagement = {
        enable = false;
        finegrained = false;
      };

      open = false;

      nvidiaSettings = true;

      package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
    };
  };

  environment.sessionVariables = {
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json";
    LD_LIBRARY_PATH = lib.mkBefore ["/run/opengl-driver/lib"];
  };
}
