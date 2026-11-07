let
  oregairu-yui = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAzCNRBuxKzxKwXiLagtYVI21a3+vSxY+M7csr2bTEXL";
  recovery_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEmdC+56O3lS7zmfQXEfFYNbBlQ6GpnxZlC+M6z6SCer";
  recipients = [
    oregairu-yui
    recovery_key
  ];
in
{
  "user-password.age".publicKeys = recipients;
  "rclone-r2.conf.age".publicKeys = recipients;
}
