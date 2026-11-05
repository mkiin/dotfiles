let
  recipients = builtins.attrValues (import ./host-keys.nix);
in
{
  "user-password.age".publicKeys = recipients;
  "rclone-r2.conf.age".publicKeys = recipients;
}
