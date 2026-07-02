{ pkgs, username, ... }:
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
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
    ];
  };
}
