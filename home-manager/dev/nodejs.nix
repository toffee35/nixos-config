{pkgs, ...}: {
  home = {
    packages = with pkgs;
      [
        nodejs_25
        pnpm

        jetbrains.webstorm
      ]
      ++ (with pkgs.nodePackages; [
        npm

        typescript-language-server
        eslint
        prettier
      ]);
  };
}
