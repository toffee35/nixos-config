{ config, lib, ... }:

with lib;
{
  options.modules.user = {
    name = mkOption {
      type = types.str;
      default = "n";
      description = "Primary user account name";
    };
  };
}
