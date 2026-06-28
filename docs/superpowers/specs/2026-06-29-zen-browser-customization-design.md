# Zen Browser カスタマイズ設計

## 目的

home-manager で管理している Zen Browser（`zen-browser-flake` の beta モジュール）の設定が
ほぼ空（`browser.tabs.warnOnClose` とブックマークのみ）の状態を、宣言的に拡張する。
対象領域: Zen 設定画面（`about:preferences`）の全カテゴリ（Look and Feel / Appearance /
Tab Management / Tabs and Browsing / Privacy and Security / Permissions and Data /
Downloads / Accessibility / Languages）を pref として宣言。加えて Spaces・見た目（mods）・フォント。
Account and Sync と Passwords and Autofill は対話的（後述）のため pref 化は最小限。

## 対象ファイル / ホスト

- 編集対象: `home-manager/desktop/zen/default.nix`
- 有効ホスト: `nixosConfigurations.nixos`。zen は `hosts/nixos/default.nix` の `home-manager.users.mkiin.imports` が `home-manager/desktop` を取り込むことで、NixOS システム設定の一部として組み込まれる。適用は `sudo nixos-rebuild switch --flake .#nixos`（home-manager standalone の switch ではない）
- フォントは `nixos/core/fonts/default.nix` で同ホストに導入済み（Noto CJK / JetBrainsMono Nerd Font / UDEV Gothic / Inter）

## スコープ外

- 検索エンジン・拡張機能・containers・pins・keyboardShortcuts・userChrome
- UI 自体の日本語化（langpack 依存のため見送り）
- Account and Sync（Mozilla/Zen アカウントへのログインが必要な対話的設定。pref 化不可のため変更なし）
- Passwords and Autofill（built-in を使う方針。保存・自動入力は既定のまま、無効化 pref を入れない）
- アクセントカラー（`zen.theme.accent-color`）は好みで都度 GUI 設定する想定のため未宣言

## 変更内容

`programs.zen-browser.profiles.default` に以下を追加する。既存の `warnOnClose`・`bookmarks` は維持。

### settings（pref）

```nix
settings = {
  "browser.tabs.warnOnClose" = false;

  # Look and Feel / Appearance
  "zen.welcome-screen.seen" = true;
  "zen.watermark.enabled" = false;
  "zen.view.compact.hide-tabbar" = true;
  "zen.urlbar.behavior" = "float";
  "browser.toolbars.bookmarks.visibility" = "always";
  "browser.aboutConfig.showWarning" = false;

  # Tab Management / Tabs and Browsing
  "zen.workspaces.continue-where-left-off" = true;
  "browser.startup.page" = 3;
  "browser.tabs.closeWindowWithLastTab" = false;
  "browser.ctrlTab.sortByRecentlyUsed" = true;
  "zen.tabs.dim-pending" = true;
  "zen.ctrlTab.show-pending-tabs" = true;
  "extensions.pocket.enabled" = false;
  "browser.urlbar.quicksuggest.enabled" = false;
  "browser.urlbar.suggest.quicksuggest.sponsored" = false;
  "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;

  # Privacy and Security
  "privacy.trackingprotection.enabled" = true;
  "privacy.trackingprotection.socialtracking.enabled" = true;
  "privacy.globalprivacycontrol.enabled" = true;
  "dom.security.https_only_mode" = true;
  "network.cookie.cookieBehavior" = 5;
  "network.trr.mode" = 2;
  "datareporting.healthreport.uploadEnabled" = false;
  "toolkit.telemetry.enabled" = false;
  "browser.newtabpage.activity-stream.feeds.telemetry" = false;

  # Permissions and Data（通知のみブロック / 自動再生は音声のみ）
  "permissions.default.desktop-notification" = 2;
  "dom.push.enabled" = false;
  "media.autoplay.default" = 1;

  # Downloads
  "browser.download.useDownloadDir" = true;
  "browser.download.folderList" = 2;
  "browser.download.dir" = "/home/mkiin/Downloads";

  # Accessibility
  "widget.gtk.overlay-scrollbars.enabled" = false;
  "findbar.highlightAll" = true;

  # Languages（Accept-Language ヘッダのみ。UI日本語化は対象外）
  "intl.accept_languages" = "ja,en-US,en";

  # Fonts（ja = 日本語 / x-western = 欧文）
  "font.name.serif.ja" = "Noto Serif CJK JP";
  "font.name.sans-serif.ja" = "Noto Sans CJK JP";
  "font.name.monospace.ja" = "UDEV Gothic";
  "font.default.ja" = "sans-serif";
  "font.name.serif.x-western" = "Noto Serif";
  "font.name.sans-serif.x-western" = "Inter";
  "font.name.monospace.x-western" = "JetBrainsMono Nerd Font";
};
```

#### 整数値 pref の意味（参考）

- `browser.startup.page` = `3`（前回のウィンドウとタブを復元）
- `browser.download.folderList` = `2`（カスタムディレクトリ＝`browser.download.dir` を使用）
- `network.cookie.cookieBehavior` = `5`（Total Cookie Protection / dFPI）
- `network.trr.mode` = `2`（DoH 有効・失敗時は通常 DNS にフォールバック）
- `permissions.default.desktop-notification` = `2`（ブロック。`0`=都度確認 / `1`=許可）
- `media.autoplay.default` = `1`（音声付きメディアをブロック。`0`=全許可 / `5`=全ブロック）

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
- `dom.security.https_only_mode = true`: HTTP のみのサイトで警告ページが出る（続行は可能）。
- `network.trr.mode = 2`（DoH 有効・既定プロバイダ Cloudflare）: ネットワーク環境によっては名前解決に影響しうる。不要なら外す。
- `browser.download.dir = "/home/mkiin/Downloads"` はホスト固有の絶対パス。ディレクトリが無ければ Zen が作成する。

## 検証（成功基準）

1. `sudo nixos-rebuild switch --flake .#nixos` がビルド・適用成功
2. Zen 再起動後、`about:config` で各 pref が設定値になっている
3. Space に Personal / Dev が出ている
4. UI mod（Top Sites 非表示など）が効いている
5. 日本語ページのフォントが Noto Sans CJK JP、等幅が UDEV Gothic で表示される

## コメント方針

- mod UUID の名前コメントは残す（UUID→名前の対応は不可欠）
- settings のグループ見出しコメントは実装時にプロジェクトのコメント方針に照らして精査
