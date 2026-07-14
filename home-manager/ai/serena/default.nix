_: {
  # serena 本体は mcp-servers-nix の derivation に内包（PATH には載せない）。
  # context は claude-code/codex 両対応の汎用のまま既定に任せる。
  programs.mcp.enable = true;
  mcp-servers.programs.serena.enable = true;
  # 起動ごとにダッシュボードのブラウザが立ち上がるのを止める
  mcp-servers.programs.serena.enableWebDashboard = false;
}
