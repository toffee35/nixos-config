{
  username,
  pkgs,
  ...
}: {
  boot = {
    kernelModules = ["kvm-intel"];
    extraModprobeConfig = "options kvm_intel nested=1";
  };

  programs.virt-manager.enable = true;

  virtualisation = {
    libvirtd = {
      enable = true;

      nss = {
        enable = true;
        enableGuest = true;
      };

      qemu = {
        package = pkgs.qemu_kvm;
        vhostUserPackages = [pkgs.virtiofsd];
        runAsRoot = true;
        swtpm.enable = true;
      };
    };

    spiceUSBRedirection.enable = true;
  };

  users.groups.libvirtd.members = [username];

  services = {
    qemuGuest.enable = true;
    spice-vdagentd.enable = true;
  };
}
