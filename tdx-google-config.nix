{
  lib,
  pkgs,
  ...
}:
let
  # Minimal TEE kernel built from custom config for AMD SEV-SNP
  # Use ccacheStdenv only when flake's ccache overlay is active (teemagerCcacheEnabled marker)
  # This avoids conflicts with global NixOS programs.ccache.enable
  minimalTeeKernel = import ./minimal-tee-kernel.nix ({
    inherit pkgs lib;
    platform = "amd";
  } // lib.optionalAttrs (pkgs ? teemagerCcacheEnabled) {
    stdenv = pkgs.ccacheStdenv;
  });
in
{
  # Use minimal TEE kernel
  boot.kernelPackages = pkgs.linuxPackagesFor minimalTeeKernel;

  boot.initrd.kernelModules = ["virtio_scsi"];
  boot.kernelModules = ["virtio_pci" "virtio_net"];

  # Force getting the hostname from Google Compute.
  networking.hostName = lib.mkForce "";

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
