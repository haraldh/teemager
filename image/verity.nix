{ config
, pkgs
, lib
, modulesPath
, ukiPath
, espSize
, ...
}:
let
  inherit (config.image.repart.verityStore) partitionIds;
  ukicfg = config.boot.uki;
in
{
  imports = [
    "${toString modulesPath}/image/repart.nix"
  ];

  ec2.efi = true;

  fileSystems = {
    "/" = {
      fsType = "tmpfs";
      options = [ "mode=0755" ];
    };

    "/usr" = {
      device = "/dev/mapper/usr";
      # explicitly mount it read-only otherwise systemd-remount-fs will fail
      options = [ "ro" ];
      fsType = config.image.repart.partitions.${partitionIds.store}.repartConfig.Format;
    };

    # bind-mount the store
    "/nix/store" = {
      device = "/usr/nix/store";
      options = [ "bind" ];
    };
  };

  image.repart = {
    mkfsOptions = {
      squashfs = [ "-no-hardlinks" ];
      erofs = [ "--hard-dereference" ];
    };

    verityStore = {
      enable = true;
      # by default the module works with systemd-boot, for simplicity this test directly boots the UKI
      inherit ukiPath;
    };

    sectorSize = 512;

    partitions = {
      ${partitionIds.esp} = {
        # the UKI is injected into this partition by the verityStore module
        repartConfig = {
          Type = "esp";
          Format = "vfat";
          SizeMinBytes = espSize;
        };
      };
      ${partitionIds.store-verity}.repartConfig = {
        Minimize = "best";
      };
      ${partitionIds.store}.repartConfig = {
        Minimize = "best";
        Format = "erofs";
        Compression = "lz4hc";
      };
    };
  };

  boot = {
    loader.grub.enable = false;
    initrd.systemd.enable = true;
    initrd.systemd.dmVerity.enable = true;
    uki = {
      name = "nixattestedami";
      version = config.system.image.version;
      tries = 3; # Enable automatic boot assessment
    };
  };

  system.build.vmdk_verity =
    config.system.build.finalImage.overrideAttrs
      (
        finalAttrs: previousAttrs:
          let
            kernel = ukicfg.settings.UKI.Linux;
            ukifile = "${config.system.build.uki}/${config.system.boot.loader.ukiFile}";
          in
          {
            postInstall = ''
              echo "kernel: ${kernel}"
              echo "uki: ${ukifile}"

              cp ${config.boot.uki.settings.UKI.Linux} $out/linux-kernel
              cp ${config.boot.uki.settings.UKI.Initrd} $out/linux-initramfs
              echo ${config.boot.uki.settings.UKI.Cmdline} > $out/linux-cmdline
              cp ${ukifile} $out/linux-uki

              ${lib.getExe pkgs.calc-tee-pcrs-rtmr} \
               --disk-image $out/${config.image.baseName}.raw \
               --uki "${ukifile}" | tee $out/pcr_rtmr.json
            '';
          }
      );

  formatAttr = lib.mkForce "vmdk_verity";
  fileExtension = lib.mkForce ".raw";
}
