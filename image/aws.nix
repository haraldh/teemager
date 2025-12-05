{
  ...
}:
{
    # EC2 has its own NTP server provided by the hypervisor
    networking.timeServers = ["169.254.169.123"];
}
