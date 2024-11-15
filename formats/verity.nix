{
  config,
  pkgs,
  lib,
  modulesPath,
  options,
  ...
}: let
  inherit (config.image.repart.verityStore) partitionIds;
in {
  imports = [
    "${toString modulesPath}/image/repart.nix"
  ];

  ec2.efi = true;

  fileSystems = {
    "/" = {
      fsType = "tmpfs";
      options = ["mode=0755"];
    };

    "/usr" = {
      device = "/dev/mapper/usr";
      # explicitly mount it read-only otherwise systemd-remount-fs will fail
      options = ["ro"];
      fsType = config.image.repart.partitions.${partitionIds.store}.repartConfig.Format;
    };

    # bind-mount the store
    "/nix/store" = {
      device = "/usr/nix/store";
      options = ["bind"];
    };
  };

  image.repart = {
    verityStore = {
      enable = true;
      # by default the module works with systemd-boot, for simplicity this test directly boots the UKI
      ukiPath = "/EFI/BOOT/BOOTx64.EFI";
    };

    partitions = {
      ${partitionIds.esp} = {
        # the UKI is injected into this partition by the verityStore module
        repartConfig = {
          Type = "esp";
          Format = "vfat";
          SizeMinBytes = "64M";
        };
      };
      ${partitionIds.store-verity}.repartConfig = {
        Minimize = "best";
      };
      ${partitionIds.store}.repartConfig = {
        Minimize = "best";
      };
    };
  };

  boot = {
    loader.grub.enable = false;
    initrd.systemd.enable = true;
  };

  system.image = {
    id = lib.mkDefault "nixos-appliance";
    version = "1";
  };

  # don't create /usr/bin/env
  # this would require some extra work on read-only /usr
  # and it is not a strict necessity
  system.activationScripts.usrbinenv = lib.mkForce "";

  boot.kernelParams = [
    "panic=30"
    "boot.panic_on_fail" # reboot the machine upon fatal boot issues
    "lockdown=1"
    "console=ttyS0,115200n8"
    "random.trust_cpu=on"
  ];
  #networking.hostName = lib.mkDefault "nixos";

  formatAttr = lib.mkForce "finalImage";
  fileExtension = lib.mkForce ".raw";
}
