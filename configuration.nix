{
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    "${toString modulesPath}/profiles/minimal.nix"
    "${toString modulesPath}/profiles/qemu-guest.nix"
    #./amazon.nix
  ];

  environment.systemPackages = with pkgs; [
    tdx_attest
    teepot.teepot
    openssl
    curl
    nixsgx.sgx-dcap.quote_verify
    nixsgx.sgx-dcap.default_qpl
  ];

  environment.variables = {
    QCNL_CONF_PATH = "${pkgs.nixsgx.sgx-dcap.default_qpl}/etc/sgx_default_qcnl.conf";
  };

  system.image.id = "nixos-appliance-test";

  boot.enableContainers = lib.mkDefault false;
  boot.initrd.systemd.enable = lib.mkDefault true;
  boot.kernelParams = [
    "console=ttyS0,115200n8"
  ];
  boot.initrd.availableKernelModules = [
    "tdx_guest"
  ];

  services.logind.extraConfig = ''
    NAutoVTs=0
    ReserveVT=0
  '';
  console.enable = false;

  #services.getty.autologinUser = lib.mkOverride 999 "root";

  boot.initrd.systemd.tpm2.enable = lib.mkForce false;
  systemd.tpm2.enable = lib.mkForce false;

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  documentation.info.enable = lib.mkForce false;
  documentation.nixos.enable = lib.mkForce false;
  documentation.man.enable = lib.mkForce false;
  documentation.enable = lib.mkForce false;

  networking.useNetworkd = lib.mkDefault true;
  networking.firewall.allowedTCPPorts = [22];
  networking.firewall.allowPing = true;

  nix.enable = false;

  programs.command-not-found.enable = lib.mkDefault false;
  programs.less.lessopen = lib.mkDefault null;

  services.sshd.enable = true;
  services.openssh.settings.PermitRootLogin = lib.mkOverride 999 "yes";

  services.udisks2.enable = false; # udisks has become too bloated to have in a headless system

  system.disableInstallerTools = lib.mkForce true;
  system.stateVersion = lib.version;
  system.switch.enable = lib.mkForce false;

  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIDsb/Tr69YN5MQLweWPuJaRGm+h2kOyxfD6sqKEDTIwoAAAABHNzaDo= harald@fedora.fritz.box"
    "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBACLgT81iB1iWWVuXq6PdQ5GAAGhaZhSKnveQCvcNnAOZ5WKH80bZShKHyAYzrzbp8IGwLWJcZQ7TqRK+qZdfagAAAAEc3NoOg== harald@hoyer.xyz"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAYbUTKpy4QR3s944/hjJ1UK05asFEs/SmWeUbtS0cdA660sT4xHnRfals73FicOoz+uIucJCwn/SCM804j+wtM="
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMNsmP15vH8BVKo7bdvIiiEjiQboPGcRPqJK0+bH4jKD harald@lenovo.fritz.box"
  ];
}
