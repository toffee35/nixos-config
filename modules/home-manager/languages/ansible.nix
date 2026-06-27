{
  username,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    ansible
    ansible-lint
  ];

  programs.vscode.profiles.${username}.extensions = with pkgs.vscode-extensions; [
    redhat.ansible
  ];
}
