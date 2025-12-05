{
  description = "AWS SEV-SNP and gcp TDX";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";

    calc-tee-pcrs-rtmr-flake = {
      url = "github:haraldh/calc-tee-pcrs-rtmr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      calc-tee-pcrs-rtmr-flake,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        # Detect ccache availability via environment variable (requires --impure)
        # Usage: NIX_CCACHE_DIR=/var/cache/ccache nix build --impure .#aws-raw-image
        ccacheDir = builtins.getEnv "NIX_CCACHE_DIR";
        useCcache = ccacheDir != "";

        # Ccache overlay for kernel builds
        ccacheOverlay =
          final: prev:
          if useCcache then
            let
              ccacheStdenv' = builtins.trace "Building kernel with ccache (${ccacheDir})" prev.ccacheStdenv;
            in
            {
              ccacheWrapper = prev.ccacheWrapper.override {
                extraConfig = ''
                  export CCACHE_COMPRESS=1
                  export CCACHE_DIR="${ccacheDir}"
                  export CCACHE_UMASK=007
                '';
              };

              # Marker to distinguish flake's ccache from global NixOS ccache
              teemagerCcacheEnabled = true;

              # Expose ccacheStdenv for use by minimal-tee-kernel.nix
              ccacheStdenv = ccacheStdenv';

              linuxPackages_6_12 = prev.linuxPackages_6_12.extend (
                lpFinal: lpPrev: {
                  kernel = lpPrev.kernel.override {
                    stdenv = ccacheStdenv';
                  };
                }
              );
            }
          else
            { };

        overlays = [
          calc-tee-pcrs-rtmr-flake.overlays.default
          ccacheOverlay
        ];

        pkgs = import nixpkgs {
          inherit system overlays;
        };

        tee-image =
          {
            userConfig ? { },
            cloudConfig ? { },
            isDebug ? false,
            secureBootData ? null,
          }:
          pkgs.callPackage ./image/lib.nix {
            inherit
              userConfig
              cloudConfig
              isDebug
              secureBootData
              ;
            inherit (nixpkgs.lib) nixosSystem;
          };
      in
      {
        packages = rec {
          default = aws-raw-image;

          aws-raw-image = tee-image {
            cloudConfig = import ./image/aws.nix;
            userConfig = import ./configuration.nix;
            isDebug = false;
          };

          aws-raw-image-debug = tee-image {
            cloudConfig = import ./image/aws.nix;
            userConfig = import ./configuration.nix;
            isDebug = true;
          };

          gcp-tdx-image = tee-image {
            cloudConfig = import ./image/gcp.nix;
            userConfig = import ./configuration.nix;
            isDebug = false;
          };

          gcp-tdx-image-debug = tee-image {
            cloudConfig = import ./image/gcp.nix;
            userConfig = import ./configuration.nix;
            isDebug = true;
          };
        };

        # For `nix run`
        apps =
          let
            boot-uefi-qemu-app = pkgs.callPackage ./utils/boot-uefi-qemu.nix { };
            create-ami-app = pkgs.callPackage ./utils/create-ami.nix { };
            create-gcp-app = pkgs.callPackage ./utils/create-gcp.nix { };
          in
          rec {
            default = boot-uefi-qemu;
            boot-uefi-qemu = {
              type = boot-uefi-qemu-app.type;
              program = boot-uefi-qemu-app.program;
            };
            create-ami = {
              type = create-ami-app.type;
              program = create-ami-app.program;
            };
            create-gcp = {
              type = create-gcp-app.type;
              program = create-gcp-app.program;
            };
          };

        # For `nix develop`
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            awscli2
            calc-tee-pcrs-rtmr
            openssl
            pkg-config
            swtpm
            google-cloud-sdk-gce
          ];
        };
      }
    );
}
