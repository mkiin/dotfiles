let
  yui = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAzCNRBuxKzxKwXiLagtYVI21a3+vSxY+M7csr2bTEXL";
  recipients = [ yui ];
in
{
  "user-password.age".publicKeys = recipients;
  "rclone-r2.conf.age".publicKeys = recipients;
}
