{ config, pkgs, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Declarative Git configuration
  programs.git = {
    enable = true;
    settings.user = {
      name = "toffee35";
      email = "nailzagru@gmail.com";
    };
  };

  # GitHub CLI with credential helper integration
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
    };
    gitCredentialHelper.enable = true;
  };

  # Smart directory jumping (zoxide)
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Fuzzy finder (fzf) for terminal history and files
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
