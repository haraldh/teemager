{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    "${toString modulesPath}/profiles/minimal.nix"
    "${toString modulesPath}/profiles/qemu-guest.nix"
    #./amazon.nix
  ];

  system.image.id = "nixos-appliance-test";

  #services.openssh.settings.PermitRootLogin = lib.mkOverride 999 "yes";
  boot.enableContainers = lib.mkDefault false;
  boot.initrd.systemd.enable = lib.mkDefault true;
  boot.kernelParams = ["console=tty0"];

  documentation.info.enable = lib.mkDefault false;

  networking.useNetworkd = lib.mkDefault true;

  nix.enable = false;

  programs.command-not-found.enable = lib.mkDefault false;
  programs.less.lessopen = lib.mkDefault null;

  services.getty.autologinUser = lib.mkOverride 999 "root";
  services.sshd.enable = lib.mkForce false;
  services.udisks2.enable = false; # udisks has become too bloated to have in a headless system

  system.disableInstallerTools = lib.mkDefault true;
  system.stateVersion = lib.version;
  system.switch.enable = lib.mkDefault false;

  users.mutableUsers = false;
  users.users.root.password = "nixos";
}
