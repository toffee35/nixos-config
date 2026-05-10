{
  nixList,
  username,
  homedir,
  lib,
  ...
}: {
  imports = nixList ./.;

  home = {
    inherit username;
    homeDirectory = homedir;

    enableNixpkgsReleaseCheck = false;

    stateVersion = "25.11";
  };

  home.activation.createNotesDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p /mnt/Files/Notes/content
    ln -sfn /mnt/Files/Notes/content ${homedir}/Notes
  '';
}
