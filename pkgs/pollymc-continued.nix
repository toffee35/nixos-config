{
  lib,
  fetchurl,
  appimageTools,
  libglvnd,
  jdk21,
  jdk17,
  jdk8,
  jdk25,
  withNvidiaOffload ? false,
}:
let
  pname = "pollymc-continued";
  version = "9.4.1";
  src = fetchurl {
    url = "https://github.com/PollyMC-Continued/launcher/releases/download/v${version}/PollyMC-Continued-${version}-x86_64.AppImage";
    sha256 = "be66f28a3cbe1696d278d0317da46cf7cad59d0fc6f9ee46258f2da00f298146";
  };
  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;
  extraPkgs = _: [
    jdk21
    jdk17
    jdk8
    jdk25
  ];
  # The FHS environment exposes only one `java` on PATH. Tell the launcher's
  # version selector about every bundled runtime, including Java 25.
  profile = ''
    export PRISMLAUNCHER_JAVA_PATHS="${jdk8}/bin/java:${jdk17}/bin/java:${jdk21}/bin/java:${jdk25}/bin/java"
  ''
  + lib.optionalString withNvidiaOffload ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    # Minecraft 26.3 uses SDL3. Its native Wayland/EGL path selects the
    # compositor's AMD GPU despite PRIME; XWayland/GLX honors NVIDIA offload.
    export SDL_VIDEO_DRIVER=x11
    export SDL_VIDEODRIVER=x11
    # LWJGL 3.4 also detects Wayland independently of SDL and would choose
    # EGL, which Minecraft then passes to SDL's GLX loader. Keep both on X11.
    unset WAYLAND_DISPLAY
    # SDL dlopens OpenGL; Nix's loader does not search /usr/lib by default.
    export SDL_OPENGL_LIBRARY=${libglvnd}/lib/libGL.so.1
  '';
  extraInstallCommands = ''
    install -Dm644 ${contents}/org.pollymc.PollyMC.desktop \
      $out/share/applications/org.pollymc.PollyMC.desktop
    substituteInPlace $out/share/applications/org.pollymc.PollyMC.desktop \
      --replace-fail 'Exec=pollymc %U' "Exec=$out/bin/pollymc-continued %U"
    install -Dm644 ${contents}/org.pollymc.PollyMC.svg \
      $out/share/icons/hicolor/scalable/apps/org.pollymc.PollyMC.svg
    install -Dm644 ${contents}/org.pollymc.PollyMC.png \
      $out/share/icons/hicolor/256x256/apps/org.pollymc.PollyMC.png
  '';
  passthru = { inherit contents; };
  meta = {
    description = "Minecraft launcher with offline account support";
    homepage = "https://github.com/PollyMC-Continued/launcher";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
