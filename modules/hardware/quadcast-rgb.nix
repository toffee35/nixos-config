{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.hardware.quadcast-rgb;

  # Not in nixpkgs and upstream ships no flake, so the derivation lives here.
  # Pinned past the v1.0.5 tag: those commits add Quadcast 2 / 2S / Duocast
  # support (new product ids + a different protocol for the 2S).
  quadcastrgb = pkgs.stdenv.mkDerivation {
    pname = "quadcastrgb";
    version = "1.0.5-unstable-2026-05-03";

    src = pkgs.fetchFromGitHub {
      owner = "Ors1mer";
      repo = "QuadcastRGB";
      rev = "e15a81c98221a4ff3fbc86e24597ab2f47c1a388";
      hash = "sha256-9u/7hYehAdyTUz8Anxe0d3J8UacZWggGi1vIP3SUTfA=";
    };

    buildInputs = [ pkgs.libusb1 ];

    # `make install` hardcodes $HOME/.local, so build only and install by hand.
    makeFlags = [ "CC=${pkgs.stdenv.cc.targetPrefix}cc" "quadcastrgb" ];

    installPhase = ''
      runHook preInstall
      install -Dm755 quadcastrgb $out/bin/quadcastrgb
      install -Dm644 man/quadcastrgb.1.gz $out/share/man/man1/quadcastrgb.1.gz
      runHook postInstall
    '';

    meta = {
      description = "RGB control for HyperX Quadcast S / Quadcast 2 / 2S / Duocast microphones";
      homepage = "https://github.com/Ors1mer/QuadcastRGB";
      license = licenses.gpl2Only;
      mainProgram = "quadcastrgb";
      platforms = platforms.linux;
    };
  };

  # Kingston 0951 + HP 03f0 ids the tool probes for (modules/devio.c).
  deviceIds = [
    { vid = "0951"; pid = "171f"; } # HyperX Quadcast S
    { vid = "03f0"; pid = "0f8b"; }
    { vid = "03f0"; pid = "028c"; }
    { vid = "03f0"; pid = "048c"; }
    { vid = "03f0"; pid = "068c"; }
    { vid = "03f0"; pid = "098c"; } # Duocast
    { vid = "03f0"; pid = "09af"; } # Quadcast 2
    { vid = "03f0"; pid = "02b5"; } # Quadcast 2S
  ];

  # NOT services.udev.extraRules: that lands in 99-local.rules, and systemd's
  # 73-seat-late.rules is what turns TAG=="uaccess" into an actual ACL — by the
  # time 99 adds the tag, rule 73 has already been evaluated and the ACL is
  # never applied (verified live: no ACL on the mic's /dev/bus/usb node). The
  # filename must sort before 73, hence a rules package.
  udevRules = pkgs.writeTextFile {
    name = "quadcastrgb-udev-rules";
    destination = "/etc/udev/rules.d/60-quadcastrgb.rules";
    text = concatMapStrings ({ vid, pid }: ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="${vid}", ATTR{idProduct}=="${pid}", TAG+="uaccess"
    '') deviceIds;
  };
in {
  options.modules.hardware.quadcast-rgb = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable QuadcastRGB lighting controller for HyperX Quadcast microphones and udev rules";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ quadcastrgb ];

    # Upstream documents a "hyperrgb" group + MODE=0660; uaccess grants the
    # locally logged-in user the same access without a group to manage.
    services.udev.packages = [ udevRules ];
  };
}
