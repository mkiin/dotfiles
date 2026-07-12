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
      # full-auto 相当。承認は一切求めず、workspace 内の読み書き・コマンドは
      # そのまま実行する。サンドボックス外に出る操作は確認ではなく失敗させる
      # (network_access は既定 false)。
      approval_policy = "never";
      sandbox_mode = "workspace-write";

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
