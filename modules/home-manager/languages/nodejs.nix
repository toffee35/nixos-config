{pkgs, ...}: {
  home = {
    packages = with pkgs;
      [
        nodejs
        pnpm
        typescript-language-server
        eslint
        prettier
      ];
  };
}
