{
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    "${toString modulesPath}/profiles/minimal.nix"
    "${toString modulesPath}/profiles/headless.nix"
    "${toString modulesPath}/profiles/qemu-guest.nix"
    #./amazon.nix
    ./google.nix
  ];

  environment.systemPackages = with pkgs; [
    teepot.teepot
    openssl
    strace
    nixsgx.sgx-dcap.quote_verify
    nixsgx.sgx-dcap.default_qpl
    cryptsetup
    google-guest-agent
  ];

  programs.nix-ld.enable = true;

  # Sets up all the libraries to load
  programs.nix-ld.libraries = with pkgs; [
    nixsgx.sgx-dcap.quote_verify
    curl
  ];

  services.timesyncd.enable = false;
  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = [
      "time.cloudflare.com"
      "ntppool1.time.nl"
      "ntppool2.time.nl"
    ];
  };

  systemd.services."chronyd".after = ["network-online.target"];

  # ec2.enabled = true;

  system.image.id = "test_tdx";

  environment.etc."issue.d/ip.issue".text = "\\4\n";

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  /*
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest.override {
    structuredExtraConfig = with lib.kernel; {
     VIDEO = no;
     SOUND = no;
     VIRT_DRIVERS = yes;
     VIRTIO_MMIO_CMDLINE_DEVICES = yes;
    };
    ignoreConfigErrors = true;
      autoModules = false;
      preferBuiltin = false;
  });
  */

  environment.etc."sgx_default_qcnl.conf" = {
    user = "root";
    group = "root";
    mode = "0644";
    source = "${pkgs.nixsgx.sgx-dcap.default_qpl}/etc/sgx_default_qcnl.conf";
  };

  environment.variables = {
    QCNL_CONF_PATH = "${pkgs.nixsgx.sgx-dcap.default_qpl}/etc/sgx_default_qcnl.conf";
  };

  boot.initrd.systemd.enable = lib.mkDefault true;
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "systemd.verity_usr_options=panic-on-corruption"
  ];

  boot.initrd.availableKernelModules = [
    "tdx_guest"
    "nvme"
  ];

  services.logind.extraConfig = ''
    NAutoVTs=0
    ReserveVT=0
  '';

  console.enable = false;

  services.dbus.implementation = "broker";

  #services.getty.autologinUser = lib.mkOverride 999 "root";

  boot.initrd.systemd.tpm2.enable = lib.mkForce false;
  systemd.tpm2.enable = lib.mkForce false;

  documentation.info.enable = lib.mkForce false;
  documentation.nixos.enable = lib.mkForce false;
  documentation.man.enable = lib.mkForce false;
  documentation.enable = lib.mkForce false;

  networking.useNetworkd = lib.mkDefault true;
  networking.firewall.allowedTCPPorts = [22];
  networking.firewall.allowPing = true;
  nix.enable = false;
  security.pam.services.su.forwardXAuth = lib.mkForce false;
  services.sshd.enable = true;
  services.openssh.settings.PermitRootLogin = lib.mkOverride 999 "yes";

  services.udisks2.enable = false; # udisks has become too bloated to have in a headless system

  system.stateVersion = lib.version;
  system.switch.enable = lib.mkForce false;

  # Remove perl from activation
  system.etc.overlay.enable = lib.mkDefault true;
  services.userborn.enable = lib.mkDefault true;

  # Random perl remnants
  system.disableInstallerTools = lib.mkForce true;
  programs.less.lessopen = lib.mkDefault null;
  programs.command-not-found.enable = lib.mkDefault false;
  boot.enableContainers = lib.mkForce false;
  boot.loader.grub.enable = lib.mkDefault false;
  environment.defaultPackages = lib.mkDefault [];

  # Check that the system does not contain a Nix store path that contains the
  # string "perl".
  system.forbiddenDependenciesRegexes = ["perl"];

  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIDsb/Tr69YN5MQLweWPuJaRGm+h2kOyxfD6sqKEDTIwoAAAABHNzaDo= harald@fedora.fritz.box"
    "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBACLgT81iB1iWWVuXq6PdQ5GAAGhaZhSKnveQCvcNnAOZ5WKH80bZShKHyAYzrzbp8IGwLWJcZQ7TqRK+qZdfagAAAAEc3NoOg== harald@hoyer.xyz"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAYbUTKpy4QR3s944/hjJ1UK05asFEs/SmWeUbtS0cdA660sT4xHnRfals73FicOoz+uIucJCwn/SCM804j+wtM="
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMNsmP15vH8BVKo7bdvIiiEjiQboPGcRPqJK0+bH4jKD harald@lenovo.fritz.box"
  ];
}
