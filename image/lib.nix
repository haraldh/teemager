{
  pkgs,
  lib,
  system,
  stdenv,
  userConfig ? { },
  cloudConfig ? { },
  isDebug ? false,
  nixosSystem,
  ...
}:
let
  nixos-generate = import ./nixos-generate.nix;

  tee-config = {
    environment = {
      systemPackages = [
        # debugging tools
        pkgs.openssl
        pkgs.tpm2-tools
      ];
    };
  };

  # Determine the correct EFI file name based on architecture
  arch = builtins.head (builtins.split "-" stdenv.hostPlatform.system);
  efiFileName = "BOOT${if arch == "aarch64" then "aa64" else "x64"}.EFI";
  ukiPath = "/EFI/BOOT/${efiFileName}";
in
pkgs.callPackage nixos-generate {
  inherit system pkgs nixosSystem;
  modules = [
    # generic nixos configuration
    ./configuration.nix
    # tee nixos packages and environment
    tee-config
    # cloud config
    cloudConfig
    # user specific nixos config
    userConfig
    {
      _module.args.ukiPath = ukiPath;
      _module.args.espSize = "${if arch == "aarch64" then "128" else "64"}M";
    }
  ]
  ++ lib.optionals (!isDebug) [ ./asserts.nix ]
  ++ lib.optionals isDebug [ ./debug.nix ];
  formatModule = ./verity.nix;
}
