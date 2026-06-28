# Zen Browser カスタマイズ設計

## 目的

home-manager で管理している Zen Browser（`zen-browser-flake` の beta モジュール）の設定が
ほぼ空（`browser.tabs.warnOnClose` とブックマークのみ）の状態を、宣言的に拡張する。
対象領域: pref/挙動・Spaces・見た目（mods）・言語・フォント。

## 対象ファイル / ホスト

- 編集対象: `home-manager/desktop/zen/default.nix`
- 有効ホスト: `nixosConfigurations.nixos`。zen は `hosts/nixos/default.nix` の `home-manager.users.mkiin.imports` が `home-manager/desktop` を取り込むことで、NixOS システム設定の一部として組み込まれる。適用は `sudo nixos-rebuild switch --flake .#nixos`（home-manager standalone の switch ではない）
- フォントは `nixos/core/fonts/default.nix` で同ホストに導入済み（Noto CJK / JetBrainsMono Nerd Font / UDEV Gothic / Inter）

## スコープ外

- 検索エンジン・拡張機能・containers・pins・keyboardShortcuts・userChrome・テーマpref
- UI 自体の日本語化（langpack 依存のため見送り）

## 変更内容

`programs.zen-browser.profiles.default` に以下を追加する。既存の `warnOnClose`・`bookmarks` は維持。

### settings（pref）

```nix
settings = {
  "browser.tabs.warnOnClose" = false;                 # 既存

  # 定番UX
  "zen.welcome-screen.seen" = true;
  "browser.aboutConfig.showWarning" = false;
  "zen.workspaces.continue-where-left-off" = true;

  # コンパクトモード + フロートURLバー
  "zen.view.compact.hide-tabbar" = true;
  "zen.urlbar.behavior" = "float";

  # プライバシー / テレメトリ off
  "datareporting.healthreport.uploadEnabled" = false;
  "toolkit.telemetry.enabled" = false;
  "browser.newtabpage.activity-stream.feeds.telemetry" = false;

  # タブ運用
  "zen.tabs.dim-pending" = true;
  "zen.ctrlTab.show-pending-tabs" = true;

  # 言語（Accept-Language ヘッダのみ。UI日本語化は対象外）
  "intl.accept_languages" = "ja,en-US,en";

  # フォント（ja = 日本語 / x-western = 欧文）
  "font.name.serif.ja" = "Noto Serif CJK JP";
  "font.name.sans-serif.ja" = "Noto Sans CJK JP";
  "font.name.monospace.ja" = "UDEV Gothic";
  "font.default.ja" = "sans-serif";
  "font.name.serif.x-western" = "Noto Serif";
  "font.name.sans-serif.x-western" = "Inter";
  "font.name.monospace.x-western" = "JetBrainsMono Nerd Font";
};
```

### spaces

```nix
spacesForce = true;
spaces = {
  "Personal" = { id = "5d4c9e3d-e72a-4bd3-9c28-a0890768ded1"; position = 1000; icon = "🏠"; };
  "Dev"      = { id = "e3e428d8-c7e8-4d3b-9e29-d10aa3f80cae"; position = 2000; icon = "💻"; };
};
```

### mods

```nix
mods = [
  "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
  "253a3a74-0cc4-47b7-8b82-996a64f030d5" # Floating History
  "803c7895-b39b-458e-84f8-a521f4d7a064" # Hide Inactive Workspaces
  "906c6915-5677-48ff-9bfc-096a02a72379" # Floating Status Bar
];
```

## 注意 / 制約

- `spacesForce = true` は既存の `zen-sessions.jsonlz4`（GUI で作った Space）を上書きする。
  適用時は **Zen を完全終了** してから switch すること。
- mods の反映にはブラウザ再起動が必要。UUID は zen-browser-flake 公式 examples の実在 mod。
- フォント/言語 pref はシステム fontconfig 既定の「ブラウザ内明示上書き」。

## 検証（成功基準）

1. `sudo nixos-rebuild switch --flake .#nixos` がビルド・適用成功
2. Zen 再起動後、`about:config` で各 pref が設定値になっている
3. Space に Personal / Dev が出ている
4. UI mod（Top Sites 非表示など）が効いている
5. 日本語ページのフォントが Noto Sans CJK JP、等幅が UDEV Gothic で表示される

## コメント方針

- mod UUID の名前コメントは残す（UUID→名前の対応は不可欠）
- settings のグループ見出しコメントは実装時にプロジェクトのコメント方針に照らして精査
