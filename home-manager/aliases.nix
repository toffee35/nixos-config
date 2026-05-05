{flakeDir, ...}: {
  home.shellAliases = {
    ll = "ls -lah";
    cle = "clear";
    ".." = "cd ..";

    code = "codium";
    lzdo = "lazydocker";

    fl-chk = "nix flake check";
    fl-up = "nix flake update --flake ${flakeDir}";
    fl-reb = "cle && fl-up && os-reb && hm-reb";
    fl-reb-f = "cle && fl-up && os-reb-f && hm-reb-f";

    nx-coll = "sudo nix-collect-garbage -d";
    nx-opt = "sudo nix store optimise";
    nx-del-gens = "sudo nix-env --delete-generations old";
    nx-gc = "sudo nix-store --gc";

    os-reb = "sudo nixos-rebuild switch --flake ${flakeDir}";
    os-reb-f = "os-reb --impure";
    hm-reb = "home-manager switch --flake ${flakeDir}";
    hm-reb-f = "hm-reb -b backup --impure";
    os-reb-boot = "sudo nixos-rebuild boot --flake ${flakeDir}";

    vm-list = "virsh list --all";
    vm-start = "virsh start";
    vm-stop = "virsh shutdown";
    vm-kill = "virsh destroy";
    vm-info = "virsh dominfo";
    vm-nets = "virsh net-list --all";

    rbt = "reboot";
    pwr = "poweroff";
  };
}
