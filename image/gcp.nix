{
  lib,
  pkgs,
  ...
}:
{
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
