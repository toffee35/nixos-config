{
  username,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs; [
      uv
      poetry
      python314FreeThreading

      ty
      ruff

      jetbrains.pycharm
    ];

    sessionVariables = {
      UV_PYTHON_DOWNLOADS = "never";
      UV_LINK_MODE = "copy";
    };
  };

  programs = {
    ty = {
      enable = true;
      settings = {};
    };

    ruff = {
      enable = true;
      settings = {};
    };

    vscode.profiles.${username}.extensions = with pkgs.vscode-extensions; [
      ms-python.python
      ms-python.debugpy
      charliermarsh.ruff
    ];
  };
}
