{pkgs, ...}: {
  home.packages = with pkgs; [
    telegram-desktop
    zoom-us

    postman
    gemini-cli

    obsidian
    chromium

    ffmpeg_8-full
    obs-studio

    prismlauncher
  ];

  programs = {
    nix-ld.enable = true;
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
