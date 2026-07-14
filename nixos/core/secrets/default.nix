{ inputs, username, ... }:
{
  imports = [ inputs.agenix.nixosModules.default ];

  # SSH host key を持たないため個人 age 鍵を復号鍵にする。activation(root) から読める。
  age.identityPaths = [ "/home/${username}/.config/agenix/key.txt" ];

  # ユーザーの rclone user service と flake app から読めるよう owner を mkiin にする。
  age.secrets."rclone-r2.conf" = {
    file = ./rclone-r2.conf.age;
    path = "/run/agenix/rclone-r2.conf";
    owner = "mkiin";
    mode = "0400";
  };

  # wallpaper-namer の user service が EnvironmentFile として読む（GEMINI_API_KEY=... の1行）。
  age.secrets."gemini-api-key.env" = {
    file = ./gemini-api-key.env.age;
    path = "/run/agenix/gemini-api-key.env";
    owner = "mkiin";
    mode = "0400";
  };

  # root が /etc/shadow 生成時に読むため owner/mode はデフォルト(root, 0400)でよい。
  age.secrets."password".file = ./password.age;
}
