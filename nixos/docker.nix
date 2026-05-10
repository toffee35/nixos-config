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
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = "5s";
  };

  users.extraGroups.docker.members = [username];
}
