{
  pkgs,
  lib,
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

  # Create users from SSH key configurations (only if sshUsers provided)
  users.users = {
    appuser = {
      isSystemUser = true;
      group = "appuser";
    };
  };

  users.groups.appuser = { };

  services.udev.extraRules = ''
    # Handle both names seen on kernels: sev-guest and sev
    SUBSYSTEM=="misc", KERNEL=="sev-guest", MODE="0660", OWNER="appuser", GROUP="root"
    SUBSYSTEM=="misc", KERNEL=="sev",       MODE="0660", OWNER="appuser", GROUP="root"
    SUBSYSTEM=="tpm",  KERNEL=="tpm[0-9]*", MODE="0660", OWNER="appuser", GROUP="root"
  '';

  system.stateVersion = "25.11";
}
