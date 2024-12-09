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
sudo qemu-system-x86_64-uefi \
  -accel kvm \
  -cpu host -smp 4 -m 8G \
  -drive file=img.qcow2 \
  -net nic,model=virtio,macaddr=52:54:00:00:00:01 -net bridge,br=virbr0
```


```shell
qemu-img convert -f raw -O vmdk  result/*.raw test_tdx.vmdk
gsutil cp test_tdx.vmdk gs://tdx_vms
gcloud migration vms image-imports create \
   --location=us-central1 \
   --target-project=tdx-pilot \
   --project=tdx-pilot \
   --skip-os-adaptation \
   --source-file=gs://tdx_vms/test_tdx.vmdk \
   tdx-img 
gcloud compute images create \
   --project tdx-pilot \
   --guest-os-features=UEFI_COMPATIBLE,TDX_CAPABLE,GVNIC,VIRTIO_SCSI_MULTIQUEUE \
   --storage-location=us-central1 \
   --source-image=tdx-img \
   tdx-img-final 
gcloud compute instances create tdx-pilot \
   --machine-type c3-standard-4 --zone us-central1-c \
   --confidential-compute-type=TDX \
   --maintenance-policy=TERMINATE \
   --image-project=tdx-pilot \
   --project tdx-pilot \
   --image tdx-img-final
```
