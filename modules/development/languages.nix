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

      # uv otherwise builds venvs on the nixpkgs python, whose loader ignores
      # NIX_LD_LIBRARY_PATH — so pip wheels die on libstdc++.so.6 and torch
      # cannot find libcuda.so.1. uv's own downloaded CPython is an ordinary
      # dynamically linked binary that runs through nix-ld, which already
      # carries libstdc++ and the Nvidia driver libs (modules/apps/default.nix).
      # Verified: numpy imports and cuDeviceGetCount reports the GPU, with no
      # LD_LIBRARY_PATH set. Existing venvs keep their old interpreter until
      # recreated.
      home.sessionVariables.UV_PYTHON_PREFERENCE = "only-managed";

      home.packages = with pkgs; [
        # Python Stack
        pythonEnv
        uv

        # Go Stack
        go
        gopls
        go-tools # staticcheck
        delve

        # JavaScript
        nodejs
        pnpm
        tsx # run .ts files directly

        # Infrastructure as Code
        terraform
        terraform-ls

        # Global build tools and libraries for Rust/Python compiling
        pkg-config
        openssl
        gcc
        gnumake # Run Makefile targets.
        just

        # JetBrains IDEs
        jetbrains.pycharm
        jetbrains.rust-rover
        jetbrains.webstorm
        jetbrains.goland

        # Zed Editor
        zed-editor

        # Remaining toolchains, installed globally (no per-project devShells).
        typescript
        bun
        rustc
        cargo
        rustfmt
        clippy
        cargo-audit
        cargo-deny
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
            golang.go
            hashicorp.terraform
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
