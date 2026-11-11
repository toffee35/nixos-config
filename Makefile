.PHONY: check build boot fmt

check:
	nix flake check

build:
	nix build .\#nixosConfigurations.laptop.config.system.build.toplevel

boot:
	sudo nixos-rebuild boot --flake .\#laptop

fmt:
	nix fmt
