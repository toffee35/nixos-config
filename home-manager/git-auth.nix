{...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*".AddKeysToAgent = "yes";
      "github-main" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
      };
      "github-work" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_work";
      };
    };
  };

  programs.git = {
    settings.user.email = "nailzagru@gmail.com";
    settings.user.name = "Toffee35";
  };
}
