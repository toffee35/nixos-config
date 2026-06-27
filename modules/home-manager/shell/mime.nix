{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
    eog
  ];

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "video/*" = "vlc.desktop";
      "audio/*" = "vlc.desktop";
      "image/*" = "eog.desktop";
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
      "application/x-zerosize" = "codium.desktop";
      "application/octet-stream" = "codium.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/chrome" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
      "application/sql" = "codium.desktop";
    };
  };
}
