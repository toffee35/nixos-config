{
  nixList,
  username,
  homedir,
  lib,
  pkgs,
  ...
}: {
  imports = nixList ./.;

  home = {
    inherit username;
    homeDirectory = homedir;

    enableNixpkgsReleaseCheck = false;

    stateVersion = "25.11";
  };

  systemd.user.services.blueman-applet = {
    Unit.After = ["graphical-session.target"];
    Service.ExecStart = lib.mkForce "${pkgs.blueman}/bin/blueman-applet";
  };

  home.activation.createNotesDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p /mnt/Files/Notes/content
    ln -sfn /mnt/Files/Notes/content ${homedir}/Notes
  '';
}
