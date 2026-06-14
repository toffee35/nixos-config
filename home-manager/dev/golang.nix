{
  pkgs,
  username,
  ...
}: {
  home.packages = with pkgs; [
    go
    gopls
    wails

    jetbrains.goland
  ];

  programs.vscode.profiles.${username}.extensions = with pkgs.vscode-extensions; [
    golang.go
  ];
}
