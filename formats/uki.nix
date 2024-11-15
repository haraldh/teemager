{
  config,
  pkgs,
  lib,
  modulesPath,
  options,
  ...
}: {
  imports = [
    "${toString modulesPath}/installer/netboot/netboot.nix"
  ];

  boot.uki.settings.UKI.Initrd = "${config.system.build.netbootRamdisk}/${config.system.boot.loader.initrdFile}";

  boot.uki.name = "bootx64";

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.kernelParams = [
    "panic=30"
    "boot.panic_on_fail" # reboot the machine upon fatal boot issues
    "random.trust_cpu=on"
  ];
  networking.hostName = lib.mkDefault "uki";

  formatAttr = lib.mkForce "uki";
  fileExtension = lib.mkForce ".efi";
}
