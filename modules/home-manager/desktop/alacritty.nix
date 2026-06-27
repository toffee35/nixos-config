{...}: {
  programs.alacritty = {
    enable = true;

    settings = {
      font.size = 9.0;
    };
  };

  home.sessionVariables.TERMINAL = "alacritty";
}
