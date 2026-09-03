{
  inputs,
  lib,
  pkgs,
  homeDirectory,
  username,
  ...
}:
let
  ghqDir = "${homeDirectory}/ghq/github.com/${username}";
  # Codex を信頼させるリポジトリ。project trust は本来 config.toml への実行時書き込みだが
  # config.toml は nix 管理の read-only symlink で TUI からは永続化できないため、
  # 信頼するリポはここに宣言する (使いたいリポを足して nix run .#switch)。
  trustedRepos = [
    "${ghqDir}/dotfiles"
    "${ghqDir}/airmonitor"
  ];
in
{
  programs.codex = {
    enable = true;
    package = pkgs.llm-agents.codex;
    enableMcpIntegration = true;

    settings = {
      # 通常は workspace 内で実行し、.git など保護対象への書き込みだけ権限昇格へ
      # 回す。managed.rules で許可したコマンドは確認なしで実行できる。
      approval_policy = "on-request";
      sandbox_mode = "workspace-write";
      sandbox_workspace_write.network_access = true;

      projects = lib.genAttrs trustedRepos (_: {
        trust_level = "trusted";
      });
    };

    context = inputs.self + "/home-manager/ai/codex/files/AGENTS.md";
  };

  # execpolicy の許可コマンドリスト。default.rules は Codex が実行時追記するため
  # 触らず、宣言管理分は別ファイルとして並置する (rules/ 内は全 .rules が自動ロード)。
  home.file.".codex/rules/managed.rules".source =
    inputs.self + "/home-manager/ai/codex/files/managed.rules";
}
