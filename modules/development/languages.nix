{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.development.languages;
in {
  options.modules.development.languages = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable development languages, compilers, and IDEs";
    };
  };

  config = mkIf cfg.enable {


    home-manager.users.${config.modules.user.name} = {
      home.packages = with pkgs; [
        # Python Stack
        python3
        uv
        ruff
        ty

        # JavaScript/TypeScript Stack
        nodejs
        typescript
        pnpm
        bun

        # Rust Stack
        rustc
        cargo

        # Global build tools and libraries for Rust/Python compiling
        pkg-config
        openssl
        glibc.dev
        gcc
        gnumake
        cmake

        # JetBrains IDEs
        jetbrains.pycharm
        jetbrains.rust-rover
        jetbrains.webstorm
        jetbrains.goland

        # Zed Editor
        zed-editor
      ];

      # VSCodium setup via Home Manager
      programs.vscodium = {
        enable = true;
        profiles.default = {
          extensions = with pkgs.vscode-extensions; [
            rust-lang.rust-analyzer
            ms-python.python
            charliermarsh.ruff
            bbenoist.nix
          ];
          userSettings = {
            "telemetry.telemetryLevel" = "off";
            "workbench.colorTheme" = "Default Dark Modern";
            "editor.fontSize" = 14;
            "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'Courier New', monospace";
          };
        };
      };
    };
  };
}
