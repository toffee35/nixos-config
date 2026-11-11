{
  description = "My NixOS configuration flake for Laptop";

  # Binary caches for nix CLI (nix build, nix flake check) on any machine.
  # System-level caches are configured separately in modules/nix-settings.nix.
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cachix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cachix.cachix.org-1:eWNHQldwUO7g2aNKvzY5aa4a2/S5S/EJ5Ry2m7JU5Bo="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    l5p-keyboard-rgb = {
      url = "github:4JX/L5P-Keyboard-RGB";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Own fork: carries the flake/module plus the Quadcast 2S acknowledgement
    # fix that is still pending upstream as PR #32. Point this back at
    # github:Ors1mer/QuadcastRGB once both are merged.
    quadcastrgb = {
      url = "github:toffee35/QuadcastRGB/flake-and-qs2s-fix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      home-manager,
      nixos-hardware,
      l5p-keyboard-rgb,
      antigravity,
      quadcastrgb,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      laptop = self.nixosConfigurations.laptop.config;
    in
    {
      formatter.${system} = pkgs.nixfmt-tree;
      packages.${system}.secrets-migrator = pkgs.writeShellApplication {
        name = "migrate-secrets";
        runtimeInputs = with pkgs; [
          sops
          ssh-to-age
          coreutils
        ];
        text = builtins.readFile ./scripts/migrate-secrets.sh;
      };
      checks.${system} = {
        hyprland = pkgs.runCommand "hyprland-config-check" { } ''
          export XDG_RUNTIME_DIR="$TMPDIR"
          ${pkgs.hyprland}/bin/Hyprland --verify-config \
            -c ${laptop.home-manager.users.n.xdg.configFile."hypr/hyprland.lua".source} \
            > "$out" 2>&1
        '';
        configuration =
          assert !laptop.services.auto-cpufreq.enable;
          assert laptop.services.tlp.enable;
          assert builtins.all (c: pkgs.lib.hasInfix "@sha256:" c.image) (
            builtins.attrValues laptop.virtualisation.oci-containers.containers
          );
          assert !(laptop.home-manager.users.n.home.sessionVariables ? PKG_CONFIG_PATH);
          pkgs.runCommand "configuration-invariants" { } "touch $out";
        scripts =
          pkgs.runCommand "maintenance-shellcheck"
            {
              nativeBuildInputs = [ pkgs.shellcheck ];
            }
            ''
              shellcheck ${./scripts/migrate-secrets.sh}
              touch "$out"
            '';
      };
      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          disko.nixosModules.disko
          ./disko.nix
          nixos-hardware.nixosModules.lenovo-legion-16ach6h
          ./hosts/laptop/default.nix
          home-manager.nixosModules.home-manager
          inputs.sops-nix.nixosModules.sops
          ({ config, ... }: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${config.modules.user.name} = import ./home.nix;
            home-manager.extraSpecialArgs = {
              inherit inputs;
              username = config.modules.user.name;
            };
          })
        ];
      };
    };
}
