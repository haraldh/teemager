{
  ...
}:
{
  users.users = {
    appuser = {
      isSystemUser = true;
      group = "appuser";
    };
  };

  users.groups.appuser = { };

  services.udev.extraRules = ''
    # Handle both names seen on kernels: sev-guest and sev
    SUBSYSTEM=="misc", KERNEL=="sev-guest", MODE="0660", OWNER="appuser", GROUP="root"
    SUBSYSTEM=="misc", KERNEL=="sev",       MODE="0660", OWNER="appuser", GROUP="root"
    SUBSYSTEM=="tpm",  KERNEL=="tpm[0-9]*", MODE="0660", OWNER="appuser", GROUP="root"
  '';

  system.stateVersion = "25.11";
}
