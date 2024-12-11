{
  config,
  pkgs,
  lib,
  modulesPath,
  options,
  ...
}: {
  fileSystems = {
    "/" = {
      fsType = "ext4";
      device = "/dev/disk/by-id/test";
      options = ["mode=0755"];
    };
  };

  boot = {
    loader.grub.enable = false;
    initrd.systemd.enable = true;
  };

  boot.kernelParams = [
    "panic=30"
    "boot.panic_on_fail" # reboot the machine upon fatal boot issues
    "lockdown=1"
    "random.trust_cpu=on"
  ];
}
