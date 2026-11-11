{ patchelf, fetchurl }:

# 0.19.2 corrupts the R595 ET_EXEC utilities on this host (SIGSEGV in dl_main).
# Keep this scoped to rebuilding bin/* from the untouched origBin/* backups.
# Remove after a newer patchelf passes nvidia-smi and nvidia-powerd smoke checks.
patchelf.overrideAttrs (_: {
  version = "0.15.2";
  src = fetchurl {
    url = "https://github.com/NixOS/patchelf/releases/download/0.15.2/patchelf-0.15.2.tar.bz2";
    hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
  };
})
