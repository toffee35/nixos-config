{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.shell.zsh;
in {
  options.modules.shell.zsh = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Zsh shell with plugins and completions";
    };
  };

  config = mkIf cfg.enable {
    # Set default shell for user
    users.users.n.shell = pkgs.zsh;
    programs.zsh.enable = true; # Needed for system shell capabilities

    home-manager.users.n = {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        
        oh-my-zsh = {
          enable = true;
          theme = "robbyrussell";
          plugins = [ "git" "sudo" "docker" ];
        };

        shellAliases = {
          ll = "ls -l";
          # Quick shortcuts for on-the-fly execution without dev shell files:
          ur = "nix run nixpkgs#";
          us = "nix shell nixpkgs#";
        };
      };
    };
  };
}
