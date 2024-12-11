{
  lib,
  pkgs,
  ...
}: {
  boot.initrd.kernelModules = ["virtio_scsi"];
  boot.kernelModules = ["virtio_pci" "virtio_net"];

  # Force getting the hostname from Google Compute.
  networking.hostName = lib.mkDefault "";

  # Configure default metadata hostnames
  networking.extraHosts = ''
    169.254.169.254 metadata.google.internal metadata
  '';

  networking.timeServers = ["metadata.google.internal"];

  environment.etc."sysctl.d/60-gce-network-security.conf".source = "${pkgs.google-guest-configs}/etc/sysctl.d/60-gce-network-security.conf";

  networking.usePredictableInterfaceNames = false;

  # GC has 1460 MTU
  networking.interfaces.eth0.mtu = 1460;

  boot.extraModprobeConfig = lib.readFile "${pkgs.google-guest-configs}/etc/modprobe.d/gce-blacklist.conf";
}
