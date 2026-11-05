{
  myvars,
  inputs,
  ...
}:

let
  userReadable = {
    mode = "0400";
    owner = myvars.username;
  };
in
{
  imports = [
    inputs.agenix.nixosModules.default
  ];
  age = {
    identityPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
    ];

    secrets = {
      "user-password" = {
        file = ./user-password.age;
        mode = "0400";
        owner = "root";
      };

      "rclone-r2.conf" = {
        file = ./rclone-r2.conf.age;
      }
      // userReadable;

    };
  };
}
