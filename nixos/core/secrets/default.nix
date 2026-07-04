{ inputs, ... }:
{
  imports = [ inputs.agenix.nixosModules.default ];

  # SSH host key を持たないため個人 age 鍵を復号鍵にする。activation(root) から読める。
  age.identityPaths = [ "/home/mkiin/.config/agenix/key.txt" ];

  # ユーザーの rclone user service と flake app から読めるよう owner を mkiin にする。
  age.secrets."rclone-r2.conf" = {
    file = ./rclone-r2.conf.age;
    path = "/run/agenix/rclone-r2.conf";
    owner = "mkiin";
    mode = "0400";
  };
}
