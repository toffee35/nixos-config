{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    prismlauncher = {
      url = "github:Diegiwg/PrismLauncher-Cracked";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nur,
    prismlauncher,
    antigravity-nix,
  }: let
    system = "x86_64-linux";

    hostname = "0NDesktop";
    username = "n";

    homedir = "/home/${username}";
    flakeDir = "${homedir}/nixos-config";

    nixList = import ./utils/nix-list.nix;

    configsArgs = {
      inherit
        system
        flakeDir
        hostname
        username
        homedir
        nixList
        ;
    };
  in {
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      specialArgs = configsArgs;

      modules = [
        ./nixos
      ];
    };

    homeConfigurations."${username}@${hostname}" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system;

        config.allowUnfree = true;
        overlays = [
          (antigravity-nix.overlays { useFHS = false; })
          nur.overlays.default
          prismlauncher.overlays.default
          (self: super: {
            libdbm = super.libdbm.overrideAttrs (oldAttrs: {
              cmakeFlags = (oldAttrs.cmakeFlags or []) ++ ["-DCMAKE_POLICY_VERSION_MINIMUM=3.5"];
            });
          })
          (self: super: {
            cxxopts = super.cxxopts.overrideAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or []) ++ [super.icu];
            });
          })
        ];
      };

      extraSpecialArgs = configsArgs;

      modules = [
        ./home-manager
      ];
    };
  };
}
