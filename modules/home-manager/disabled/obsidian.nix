{
  username,
  lib,
  homedir,
  ...
}: {
  programs.obsidian = {
    enable = true;

    defaultSettings.appearance.theme = "obsidian";

    vaults.${username} = {
      enable = true;
      target = "Notes";
    };
  };

  home.activation.createNotesDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p /mnt/Files/Notes
      ln -sfn /mnt/Files/Notes ${homedir}/Notes
    '';
}
