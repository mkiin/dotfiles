{
  myvars,
  mysecrets,
  ...
}:

let
  userReadable = {
    mode = "0400";
    owner = myvars.username;
  };
in
{
  age = {
    identityPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
    ];

    secrets = {
      "user-password" = {
        file = "${mysecrets}/user-password.age";
        mode = "0400";
        owner = "root";
      };

      "rclone-r2.conf" = {
        file = "${mysecrets}/rclone-r2.conf.age";
      }
      // userReadable;

      "nix-access-tokens" = {
        file = "${mysecrets}/nix-access-tokens.age";
      }
      // userReadable;
    };
  };
}
