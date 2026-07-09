{
  pkgs,
  username,
  config,
  ...
}:
{
  programs.zsh.enable = true;

  # nixos-rebuild のみ sudo パスワードを省略。store path 直指定だと input 更新後の
  # 初回でパスを聞かれるため、更新で変わらない固定パス(current-system)で指定する。
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    shell = pkgs.zsh;
    hashedPasswordFile = config.age.secrets."password".path;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "dialout" # ESP32 等のシリアル(/dev/ttyACM*, ttyUSB*)書き込み
    ];
  };

  users.mutableUsers = false;
  users.users.root.hashedPasswordFile = config.age.secrets."password".path;

  # secrets と鍵パスは mkiin 用にプロビジョニング済み。username がずれると復号失敗で
  # mutableUsers=false 下ではロックアウトするため build 時に弾く。
  assertions = [
    {
      assertion = username == "mkiin";
      message = "secrets/鍵パスは mkiin 用。別ユーザーで使うには age 鍵とパスワードの再暗号化が必要。username を mkiin に合わせるか再プロビジョニングせよ。";
    }
  ];
}
