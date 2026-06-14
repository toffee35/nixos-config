{...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*".addKeysToAgent = "yes";
      "github-main" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };
      "github-work" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_work";
      };
    };
  };

  programs.git = {
    settings.user.email = "nailzagru@gmail.com";
    settings.user.name = "Toffee35";
  };
}
