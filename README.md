# Reproducible builds with nix

On Ubuntu, with docker installed, the following is needed:

```shell
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
```

from the checked-out project root, run on a `x86_64` machine:

```shell
docker run --ulimit nofile=5000:5000 --platform linux/amd64 --privileged -it -v .:/mnt nixos/nix:2.32.4
```

then run inside the container shell:

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
cd /mnt/nix
nix build -L .#aws-raw-image

# copies from the container /nix storage into the project
cp -avr result/. ./build-artifacts
```

The directory `build-artifacts` should contain:

```console
$ ls build-artifacts
linux-cmdline       linux-kernel        nixos-tee_1.raw     repart-output.json
linux-initramfs     linux-uki           pcr_rtmr.json
```
