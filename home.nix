{ config, pkgs, ... }:

{
  home.username = "n";
  home.homeDirectory = "/home/n";
  home.stateVersion = "26.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
