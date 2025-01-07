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

  virtualisation.docker.enable = true;

  systemd.services.docker_start_container = {
    description = "Start Docker the measured container after network online";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "docker.service"];
    requires = ["network-online.target" "docker.service"];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    path = [pkgs.curl pkgs.docker pkgs.teepot.teepot.tdx_extend];
    script = ''
      set -eu
      CONTAINER_URL=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/container_url" -H "Metadata-Flavor: Google")
      DIGEST=$(echo -n -- "$CONTAINER_URL" | sha384sum | { read a _; echo "$a"; })
      tdx-extend --digest "$DIGEST" --rtmr 3
      docker run -d --init --privileged --rm "$CONTAINER_URL"
    '';
  };

  environment.systemPackages = with pkgs; [
    teepot.teepot
  ];

  networking.firewall.logRefusedConnections = false;

  services.journald.storage = "volatile";

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

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;
  /*
  boot.kernelPackages = pkgs.linuxPackages_custom {
    inherit (pkgs.linuxPackages_6_12.kernel) src;
    version = "6.12.3-tdx";
    configfile = ./config-6.12.3-tdx;
    };
  */
  boot.kernelPatches = [
    {
      name = "tdx-rtmr";
      patch = pkgs.fetchurl {
        url = "https://github.com/haraldh/linux/commit/12d08008a5c94175e7a7dfcee40dff33431d9033.patch";
        hash = "sha256-sVDhvC3qnXpL5FRxWiQotH7Nl/oqRBQGjJGyhsKeBTA=";
      };
    }
  ];

  boot.initrd.includeDefaultModules = false;

  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "systemd.verity_usr_options=panic-on-corruption"
  ];

  boot.consoleLogLevel = 7;

  boot.initrd.availableKernelModules = [
    "tdx_guest"
    "nvme"
    "sd_mod"
    "dm_mod"
    "ata_piix"
  ];

  boot.initrd.systemd.enable = lib.mkDefault true;

  services.logind.extraConfig = ''
    NAutoVTs=0
    ReserveVT=0
  '';

  #console.enable = false;

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
