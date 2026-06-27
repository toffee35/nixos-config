{
  username,
  pkgs,
  ...
}: {
  users.users.${username}.shell = pkgs.zsh;

  programs.zsh.enable = true;
}
