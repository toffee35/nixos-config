{
  username,
  pkgs,
  ...
}: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;

    profiles.${username} = {
      extensions = with pkgs.vscode-extensions; [
        pkief.material-icon-theme

        ms-azuretools.vscode-docker
        fill-labs.dependi

        jnoortheen.nix-ide
        kamadorueda.alejandra
        bbenoist.nix
        jeff-hykin.better-nix-syntax
      ];

      userSettings = {
        workbench = {
          iconTheme = "material-icon-theme";
          sideBar.location = "right";
        };

        explorer = {
          confirmDragAndDrop = false;
          confirmDelete = false;
        };

        editor = {
          lineNumbers = "on";
          wordWrap = "on";
          formatOnSave = true;
          codeActionsOnSave.source = {
            organizeImports = "explicit";
            fixAll = "explicit";
          };
        };

        files = {
          autoSave = "onFocusChange";
          trimTrailingWhitespace = true;
          insertFinalNewline = true;
        };

        git = {
          enableSmartCommit = true;
          confirmSync = false;
        };

        nix = {
          enableLanguageServer = true;
          serverPath = "${pkgs.nil}/bin/nil";
        };

        rust-analyzer = {
          cargo.features = "all";
        };

        dependi = {
          extras.silenceUpdateMessages = true;
        };
      };
    };
  };

  home.sessionVariables.EDITOR = "codium";
}
