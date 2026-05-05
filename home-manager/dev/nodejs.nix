{pkgs, ...}: {
  home = {
    packages = with pkgs;
      [
        nodejs_25
        pnpm
        typescript-language-server
        eslint
        prettier
      ];
  };
}
