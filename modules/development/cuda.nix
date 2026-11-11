{ config, lib, pkgs, ... }:

let
  cfg = config.modules.development.cuda;
  cudaPackages = pkgs.cudaPackages_13_2;
  rawToolkit = cudaPackages.cudatoolkit;
  standaloneToolkit = pkgs.symlinkJoin {
    pname = "cuda-toolkit";
    version = cudaPackages.cudaMajorMinorPatchVersion;
    paths = [ rawToolkit ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    # Nixpkgs normally supplies these paths through development-shell hooks.
    # Make the system-wide compiler usable from an ordinary terminal too.
    postBuild = ''
      rm "$out/bin/nvcc"
      makeWrapper ${rawToolkit}/bin/nvcc "$out/bin/nvcc" \
        --add-flags "-I$out/include -L$out/lib" \
        --add-flags "-Xlinker=-rpath -Xlinker=$out/lib" \
        --add-flags "-Xlinker=-rpath -Xlinker=/run/opengl-driver/lib"
    '';
    meta = rawToolkit.meta // { mainProgram = "nvcc"; };
  };
in {
  options.modules.development.cuda = {
    enable = lib.mkEnableOption "CUDA Toolkit for native GPU development" // {
      default = true;
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = standaloneToolkit;
      defaultText = lib.literalExpression "standaloneToolkit";
      description = "CUDA Toolkit with standalone nvcc include and library paths.";
    };
  };

  config = lib.mkIf cfg.enable {
    # CUDA 13.2 from the flake's pinned Nixpkgs, matching cu132 wheels and the
    # installed R595 driver. Keep CUDA support local to the toolkit rather
    # than rebuilding every CUDA-capable package globally.
    environment.systemPackages = [ cfg.package ];
    environment.sessionVariables = {
      CUDA_PATH = "${cfg.package}";
      CUDA_HOME = "${cfg.package}";
      # PyPI Triton otherwise invokes /sbin/ldconfig, absent on NixOS.
      # Use the running NVIDIA driver's libraries, not toolkit stubs.
      TRITON_LIBCUDA_PATH = "/run/opengl-driver/lib";
    };
  };
}
