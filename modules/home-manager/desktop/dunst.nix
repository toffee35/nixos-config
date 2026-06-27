{...}: {
  services.dunst = {
    enable = true;

    settings = {
      global = {
        font = "Inter 10";
        corner_radius = 8;
        frame_width = 1;
        frame_color = "#383c4a";
        background = "#2f343f";
        foreground = "#f3f4f5";
        padding = 10;
        horizontal_padding = 12;
      };

      urgency_low = {
        background = "#2f343f";
        foreground = "#f3f4f5";
      };

      urgency_normal = {
        background = "#2f343f";
        foreground = "#f3f4f5";
      };

      urgency_high = {
        background = "#2f343f";
        foreground = "#f3f4f5";
        frame_color = "#ef5050";
      };
    };
  };
}
