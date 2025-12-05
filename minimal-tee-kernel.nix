# Minimal TEE kernel for AMD SEV-SNP / Intel TDX guest VMs
{
  pkgs,
  lib,
  stdenv ? pkgs.stdenv,
  platform ? "amd",
}:

let
  # Use kernel 6.12 source
  kernel = pkgs.linux_6_12;

  # Select config file based on platform
  baseConfigFile =
    if platform == "intel" then ./minimal-tee-kernel-intel.config else ./minimal-tee-kernel-amd.config;

  platformDesc = if platform == "intel" then "Intel TDX" else "AMD SEV-SNP";

in
pkgs.linuxManualConfig {
  inherit (kernel) src version modDirVersion;
  inherit stdenv; # Allow passing ccacheStdenv

  # Build our config: base config + run olddefconfig
  configfile =
    pkgs.runCommand "minimal-tee-kernel-config-${platform}"
      {
        nativeBuildInputs = with pkgs; [
          gnumake
          gnutar
          gzip
          gcc
          flex
          bison
          bc
          perl
        ];
      }
      ''
        set -x
        # Extract the kernel source
        tar xf ${kernel.src}
        chmod -R u+w linux-*
        cd linux-*

        # Start with our minimal config
        cp ${baseConfigFile} .config

        # Run olddefconfig to fill in any missing options with defaults
        make olddefconfig

        cp .config $out
      '';

  # Allow config errors since we're being aggressive
  allowImportFromDerivation = true;

  kernelPatches = [
    {
      name = "tdx-rtmr";
      patch = pkgs.fetchurl {
        url = "https://github.com/haraldh/linux/commit/12d08008a5c94175e7a7dfcee40dff33431d9033.patch";
        hash = "sha256-sVDhvC3qnXpL5FRxWiQotH7Nl/oqRBQGjJGyhsKeBTA=";
      };
    }
  ];

  extraMeta = {
    description = "Minimal Linux kernel for TEE (${platformDesc}) guest VMs";
    platforms = [ "x86_64-linux" ];
  };
}
