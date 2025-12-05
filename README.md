# teemager

Reproducible NixOS images for VM-based Trusted Execution Environments (TEEs):
- **AWS SEV-SNP** - AMD Secure Encrypted Virtualization
- **Google Cloud TDX** - Intel Trust Domain Extensions

## Features

- Immutable, dm-verity protected root filesystem
- Minimal attack surface with security hardening
- Zero operator access (no SSH, no passwords, no console login)
- Debug variants available for development
- PCR/RTMR pre-calculation for attestation
- Reusable as a library for custom images

## Flake Outputs

### Packages

| Package | Description |
|---------|-------------|
| `aws-raw-image` | Production AWS SEV-SNP image (default) |
| `aws-raw-image-debug` | AWS image with root console access |
| `gcp-tdx-image` | Production Google Cloud TDX image |
| `gcp-tdx-image-debug` | GCP image with root console access |

```shell
# Build AWS image
nix build .#aws-raw-image

# Build GCP image
nix build .#gcp-tdx-image
```

### Apps

| App | Description |
|-----|-------------|
| `boot-uefi-qemu` | Boot a raw image in QEMU with TPM emulation |
| `create-ami` | Upload raw image to AWS and create AMI |
| `create-gcp` | Upload raw image to GCP and create TDX image |

```shell
# Test locally in QEMU
nix run .#boot-uefi-qemu -- result/nixos-tee_1.raw

# Deploy to AWS
nix run .#create-ami -- result/nixos-tee_1.raw

# Deploy to GCP
GCP_PROJECT=my-project GCP_LOCATION=us-central1 GCP_BUCKET=my-bucket \
  nix run .#create-gcp -- result/nixos-tee_1.raw
```

### Library (`lib`)

For building custom TEE images in your own flake:

| Export | Description |
|--------|-------------|
| `lib.mkTeeImage` | Function to create TEE images |
| `lib.cloudConfigs.aws` | AWS cloud configuration module |
| `lib.cloudConfigs.gcp` | GCP cloud configuration module |

### Overlay (`overlays.default`)

Adds `pkgs.mkTeeImage` when applied to nixpkgs.

## Building

### With Nix installed

```shell
nix build -L .#aws-raw-image
```

### With ccache (faster kernel rebuilds)

```shell
NIX_CCACHE_DIR=/var/cache/ccache nix build -L --impure .#aws-raw-image
```

### With Docker (reproducible builds)

On Ubuntu with Docker, you may need:

```shell
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
```

Then run:

```shell
docker run --ulimit nofile=5000:5000 --platform linux/amd64 --privileged -it -v .:/mnt nixos/nix:2.32.4
```

Inside the container:

```shell
cat > /etc/nix/nix.conf <<EOF
show-trace = true
max-jobs = auto
trusted-users = root runner
sandbox = true
experimental-features = nix-command flakes
always-allow-substitutes = true
build-users-group = nixbld
EOF

git config --global --add safe.directory '*'
cd /mnt
nix build -L .#aws-raw-image

# Copy artifacts out of nix store
cp -avr result/. ./build-artifacts
```

### Build Artifacts

```
linux-cmdline       # Kernel command line
linux-initramfs     # Initial ramdisk
linux-kernel        # Linux kernel
linux-uki           # Unified Kernel Image
nixos-tee_1.raw     # Raw disk image
pcr_rtmr.json       # Pre-calculated PCR/RTMR values
repart-output.json  # Partition information
```

## Deploying

### AWS

```shell
# Build and deploy
nix build -L .#aws-raw-image
nix run .#create-ami -- result/nixos-tee_1.raw
```

### Google Cloud

```shell
# Build and deploy
nix build -L .#gcp-tdx-image

GCP_PROJECT=my-project \
GCP_LOCATION=us-central1 \
GCP_BUCKET=my-bucket \
  nix run .#create-gcp -- result/nixos-tee_1.raw
```

Environment variables for `create-gcp`:
- `GCP_PROJECT` (required) - Google Cloud project ID
- `GCP_LOCATION` (required) - Location for image import (e.g., `us-central1`)
- `GCP_BUCKET` (required) - GCS bucket for VMDK upload
- `IMAGE_NAME` (optional) - Base name for the image (default: `nixos-tdx-<timestamp>`)

## Using as a Library

Use `lib.mkTeeImage` to build custom TEE images in your own flake:

```nix
{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    teemager.url = "github:haraldh/teemager";
  };

  outputs = { self, nixpkgs, teemager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      mkTeeImage = teemager.lib.mkTeeImage {
        inherit pkgs;
        inherit (nixpkgs.lib) nixosSystem;
      };
    in {
      packages.${system} = {
        # Custom AWS image with your configuration
        my-aws-image = mkTeeImage {
          cloudConfig = teemager.lib.cloudConfigs.aws;
          userConfig = {
            # Your NixOS configuration
            environment.systemPackages = [ pkgs.htop ];
          };
        };

        # Custom GCP image
        my-gcp-image = mkTeeImage {
          cloudConfig = teemager.lib.cloudConfigs.gcp;
          userConfig = import ./my-config.nix;
          isDebug = false;
        };
      };
    };
}
```

### Using the Overlay

```nix
{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    teemager.url = "github:haraldh/teemager";
  };

  outputs = { self, nixpkgs, teemager, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ teemager.overlays.default ];
      };
    in {
      packages.x86_64-linux.my-image = pkgs.mkTeeImage {
        cloudConfig = teemager.lib.cloudConfigs.aws;
        userConfig = ./my-config.nix;
      };
    };
}
```

### `mkTeeImage` Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `cloudConfig` | module | `{}` | Cloud-specific NixOS module (use `lib.cloudConfigs.*`) |
| `userConfig` | module | `{}` | Your custom NixOS configuration |
| `isDebug` | bool | `false` | Enable debug mode (root console access) |

## Development

```shell
# Enter development shell
nix develop

# Available tools: awscli2, gcloud, openssl, swtpm, etc.
```

## License

See [LICENSE](LICENSE) file.
