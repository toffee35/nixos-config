{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.development.languages;

  # Jupyter is baked into the system interpreter rather than added as separate
  # packages: jupyterlab/notebook next to a plain python3 would collide on
  # bin/python, and the kernel has to live in the same interpreter as
  # ipykernel. Project venvs stay isolated from these.
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    jupyterlab
    notebook
    ipykernel
  ]);
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
      # The env ships its kernelspec only under its own store path, which the
      # VSCodium Jupyter extension never scans — it looks in
      # ~/.local/share/jupyter — so no kernel showed up at all. The stock spec
      # also launches a bare `python`, which inside a project with an active
      # venv resolves to that venv's interpreter, one without ipykernel.
      # Pinning the absolute interpreter path avoids both.
      xdg.dataFile."jupyter/kernels/python3-system/kernel.json".text = builtins.toJSON {
        argv = [ "${pythonEnv}/bin/python" "-m" "ipykernel_launcher" "-f" "{connection_file}" ];
        display_name = "Python 3 (system, Jupyter)";
        language = "python";
        metadata.debugger = true;
      };

      home.packages = with pkgs; [
        # Python Stack
        pythonEnv
        uv
        ruff
        ty

        # JavaScript/TypeScript Stack
        nodejs
        typescript
        pnpm
        bun
        biome

        # Go Stack
        go
        gopls
        go-tools

        # Rust Stack
        rustc
        cargo

        # Global build tools and libraries for Rust/Python compiling
        pkg-config
        openssl
        glibc.dev
        gcc
        just

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
            ms-toolsai.jupyter
            ms-toolsai.jupyter-renderers
            ms-toolsai.jupyter-keymap
            ms-toolsai.vscode-jupyter-cell-tags
            charliermarsh.ruff
            bbenoist.nix
          ];
          userSettings = {
            "telemetry.telemetryLevel" = "off";
            "python.defaultInterpreterPath" = "${pythonEnv}/bin/python";
            "workbench.colorTheme" = "Default Dark Modern";
            "editor.fontSize" = 14;
            "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'Courier New', monospace";
          };
        };
      };
    };
  };
}
