let
  oregairu-yui = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAzCNRBuxKzxKwXiLagtYVI21a3+vSxY+M7csr2bTEXL";
  oregairu-yukino = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF71Mzulg4F9wwvfYVlf6r5HcWGFAwyt1ghl1N2p3oQ7";
  recovery_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEmdC+56O3lS7zmfQXEfFYNbBlQ6GpnxZlC+M6z6SCer";
  recipients = [
    oregairu-yui
    oregairu-yukino
    recovery_key
  ];
in
{
  "user-password.age".publicKeys = recipients;
  "rclone-r2.conf.age".publicKeys = recipients;
}
