# Auto-imports all modules. Each module has its own `enable` option (default: true).
# To disable a module, set `modules.<category>.<name>.enable = false` in the host config.
{
  imports = [
    ./user.nix
    ./theme.nix
    ./nix-settings.nix
    ./hardware/nvidia.nix
    ./hardware/legion-rgb.nix
    ./hardware/boot.nix
    ./desktop/hyprland.nix
    ./desktop/waybar.nix
    ./desktop/hyprlock.nix
    ./desktop/hypridle.nix
    ./desktop/wofi.nix
    ./desktop/theme-gtk.nix
    ./desktop/sddm.nix
    ./desktop/thunar.nix
    ./desktop/kitty.nix
    ./development/docker.nix
    ./development/languages.nix
    ./development/ollama.nix
    ./apps/default.nix
    ./apps/antigravity.nix
    ./shell/zsh.nix
  ];
}
