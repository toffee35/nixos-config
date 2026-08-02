# Auto-imports every .nix file in this directory tree, so a new module only has
# to be created, not registered. Each module has its own `enable` option
# (default: true). To disable a module, set `modules.<category>.<name>.enable
# = false` in the host config.
{ lib, ... }:

{
  imports =
    let
      isModule = path:
        lib.hasSuffix ".nix" (toString path) && baseNameOf path != "default.nix";
    in
    builtins.filter isModule (lib.filesystem.listFilesRecursive ./.);
}
