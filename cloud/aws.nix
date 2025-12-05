{
  pkgs,
  modulesPath,
  ...
}:
{
  systemd.services.fetch-ec2-metadata = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.curl ];
    script = builtins.readFile "${toString modulesPath}/virtualisation/ec2-metadata-fetcher.sh";
    serviceConfig.Type = "oneshot";
    serviceConfig.StandardOutput = "journal+console";
  };

  # EC2 has its own NTP server provided by the hypervisor
  networking.timeServers = [ "169.254.169.123" ];
}
