# AMD SEV-SNP TEE kernel configuration
{
  pkgs,
  lib,
  ...
}:
let
  minimalTeeKernel = import ./minimal-tee-kernel.nix (
    {
      inherit pkgs lib;
      platform = "amd";
    }
    // lib.optionalAttrs (pkgs ? teemagerCcacheEnabled) {
      stdenv = pkgs.ccacheStdenv;
    }
  );
in
{
  boot.kernelPackages = pkgs.linuxPackagesFor minimalTeeKernel;
}
