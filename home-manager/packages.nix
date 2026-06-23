{pkgs, ...}: {
  home.packages = with pkgs; [
    telegram-desktop
    zoom-us

    postman

    gemini-cli
    google-antigravity-cli
    google-antigravity-no-fhs
    opencode

    obsidian
    chromium
    google-chrome

    ffmpeg_8-full
    obs-studio

    # prismlauncher

    pavucontrol
    audiosource
    android-tools
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
