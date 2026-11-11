{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.shell.zsh;
  flakeDir = "${config.users.users.${config.modules.user.name}.home}/nixos-config";
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
    users.users.${config.modules.user.name}.shell = pkgs.zsh;
    programs.zsh.enable = true; # Needed for system shell capabilities

    home-manager.users.${config.modules.user.name} = {
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
          ll = "ls -la";
          rbld = "sudo nixos-rebuild switch --flake ${flakeDir}#laptop";
          updt = "nix flake update --flake ${flakeDir}";
          pwr  = "systemctl poweroff";
          rbt  = "systemctl reboot";
        };
      };
    };
  };
}
