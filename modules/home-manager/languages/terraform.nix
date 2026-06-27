{
  username,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    terraform
    cdrtools
  ];

  programs.vscode.profiles.${username}.extensions = with pkgs.vscode-extensions; [
    hashicorp.terraform
  ];
}
