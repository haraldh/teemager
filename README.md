# Create immutable images for VM-based TEEs

## Prepare QEMU for EFI

see https://wiki.nixos.org/wiki/QEMU and configure

```nix
{
 environment = {
   systemPackages = [
     (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
       qemu-system-x86_64 \
         -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
         "$@"
     '')
   ];
 };
}
```

## Single UKI

UKI kernel+initrd+cmdline in EFI with root in initrd in squashfs backed image.

```shell
nix build -L .#uki
mkdir -p root/EFI/boot
cp result/*.efi root/EFI/boot/bootx64.efi
qemu-system-x86_64-uefi \
  -accel kvm \
  -cpu host -smp 4 -m 2G \
  -drive format=raw,file=fat:rw:root
```

## Disk image with dm-verity

Raw disk image with UKI kernel+initrd+cmdline in EFI with root on tmpfs and /usr on dm-verity erofs partition.

```shell
nix build -L .#verity
qemu-img create -f qcow2 -b result/*.raw -F raw img.qcow2
qemu-system-x86_64-uefi \
  -accel kvm \
  -cpu host -smp 4 -m 2G \
  -drive file=img.qcow2
```
