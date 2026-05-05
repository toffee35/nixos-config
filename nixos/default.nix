{
  nixList,
  system,
  pkgs,
  username,
  ...
}: {
  imports = nixList ./.;

  system = {
    stateVersion = "25.11";

    autoUpgrade = {
      enable = true;
      allowReboot = false;
      dates = "weekly";
      flags = ["--update-input" "nixpkgs"];
    };
  };

  nixpkgs = {
    config.allowUnfree = true;

    hostPlatform = system;
  };

  networking = {
    hostName = "0NDesktop";

    networkmanager.enable = true;
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Istanbul";

  users.users.${username} = {
    isNormalUser = true;

    linger = true;

    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  nix = {
    settings = {
      builders-use-substitutes = true;
      max-jobs = "auto";
      cores = 0;

      experimental-features = [
        "nix-command"
        "flakes"
      ];

      auto-optimise-store = true;

      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };

    gc = {
      automatic = true;

      dates = "daily";
      options = "--delete-older-than 1w";

      persistent = true;
    };
  };

  security.sudo.enable = true;

  services.upower.enable = true;

  environment.systemPackages = with pkgs; [
    nano
    home-manager
  ];

  programs = {
    nix-ld.enable = true;
    dconf.enable = true;
    droidcam.enable = true;
  };
}
