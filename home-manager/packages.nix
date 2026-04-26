{pkgs, ...}: {
  home.packages = with pkgs; [
    telegram-desktop
    zoom-us

    postman

    gemini-cli
    opencode

    obsidian
    chromium

    ffmpeg_8-full
    obs-studio

    prismlauncher
  ];

  programs = {
    git = {
      enable = true;
      settings = {
        init.defaultBranch = "main";
        submodule.recurse = "true";
      };
    };
    tmux.enable = true;
    btop.enable = true;
  };
}
