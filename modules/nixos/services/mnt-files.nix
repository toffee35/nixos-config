{username, ...}: {
  fileSystems."/mnt/Files" = {
    device = "/dev/disk/by-uuid/a94cca3e-80c7-4b26-a117-11a62cb55e41";
    fsType = "ext4";
    options = [
      "nofail"
      "rw"
      "x-gvfs-show"
    ];

    neededForBoot = false;
  };

  virtualisation.docker.daemon.settings.data-root = "/mnt/Files/Docker";

  systemd.services.docker = {
    unitConfig.After = ["mnt-Files.mount"];
    unitConfig.Requires = ["mnt-Files.mount"];
    unitConfig.ConditionPathIsMountPoint = "/mnt/Files";
  };

  system.activationScripts.fixFilesOwnership.text = ''
    chown -R ${username}:users /mnt/Files || true
  '';

  system.userActivationScripts.linkHomeSymlink.text = ''
    if [ ! -L "$HOME/Files" ]; then
      ln -snf /mnt/Files "$HOME/Files"
    fi
  '';
}
