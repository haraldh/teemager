{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  inherit (lib) mkDefault mkIf;
  cfg = config.ec2;
in {
  config = {
    systemd.services.fetch-ec2-metadata = {
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      after = ["network-online.target"];
      path = [pkgs.curl];
      script = builtins.readFile "${toString modulesPath}/virtualisation/ec2-metadata-fetcher.sh";
      serviceConfig.Type = "oneshot";
      serviceConfig.StandardOutput = "journal+console";
    };

    # Amazon-issued AMIs include the SSM Agent by default, so we do the same.
    # https://docs.aws.amazon.com/systems-manager/latest/userguide/ami-preinstalled-agent.html
    # services.amazon-ssm-agent.enable = true;

    # Enable the serial console on ttyS0
    systemd.services."serial-getty@ttyS0".enable = false;

    # Creates symlinks for block device names.
    services.udev.packages = [pkgs.amazon-ec2-utils];

    # Force getting the hostname from EC2.
    networking.hostName = mkDefault "";

    # Always include cryptsetup so that Charon can use it.
    environment.systemPackages = [pkgs.cryptsetup];

    # EC2 has its own NTP server provided by the hypervisor
    networking.timeServers = ["169.254.169.123"];
  };
}
