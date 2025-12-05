{
  pkgs,
  ...
}:
let
  script = pkgs.writeShellApplication {
    name = "boot-uefi-qemu";

    runtimeInputs = with pkgs; [
      qemu
      swtpm
    ];

    text =
      let
        tpmOVMF = pkgs.OVMF.override { tpmSupport = true; };
      in
      ''
        tpmdir=$(mktemp -d)
        tmpFile=$(mktemp)
        cleanup() { [[ -f "$tpmdir/pid" ]] && kill "$(<"$tpmdir/pid")"; rm -f "$tmpFile"; rm -fr "$tpmdir"; }
        trap cleanup EXIT
        : > "$tpmdir/pid"
        swtpm socket -d --tpmstate dir="$tpmdir" --pid file="$tpmdir/pid" \
          --ctrl type=unixio,path="$tpmdir/swtpm-sock" \
          --tpm2 \
          --log level=20
        cp "$1" "$tmpFile"
        qemu-system-x86_64 \
          -cpu max \
          -enable-kvm \
          -m 4G \
          -nographic \
          -nic user,model=virtio-net-pci \
          -drive if=pflash,format=raw,readonly=on,file=${tpmOVMF.firmware} \
          -drive if=pflash,format=raw,readonly=on,file=${tpmOVMF.variables} \
          -chardev socket,id=chrtpm,path="$tpmdir/swtpm-sock" \
          -tpmdev emulator,id=tpm0,chardev=chrtpm \
          -device tpm-tis,tpmdev=tpm0 \
          -drive "format=raw,file=$tmpFile"
      '';
  };
in
{
  type = "app";
  program = "${script}/bin/boot-uefi-qemu";
}
