{username, ...}: {
  virtualisation.docker = {
    enable = true;

    rootless = {
      enable = true;

      setSocketVariable = true;
    };
  };

  systemd.user.services.docker = {
    unitConfig = {
      After = ["mnt-Files.mount"];
      Requires = ["mnt-Files.mount"];
    };
  };

  users.extraGroups.docker.members = [username];
}
