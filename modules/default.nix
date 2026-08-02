# Auto-imports every .nix file in this directory tree, so a new module only has
# to be created, not registered. Each module has its own `enable` option
# (default: true). To disable a module, set `modules.<category>.<name>.enable
# = false` in the host config.
{ lib, ... }:

{
  imports =
    let
      # Only this very file is skipped. Excluding every default.nix would drop
      # real modules: modules/apps/default.nix is one.
      isModule = path:
        lib.hasSuffix ".nix" (toString path) && toString path != toString ./default.nix;
    in
    builtins.filter isModule (lib.filesystem.listFilesRecursive ./.);
}
