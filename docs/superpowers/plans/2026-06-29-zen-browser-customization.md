# Zen Browser カスタマイズ Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** home-manager 管理の Zen Browser に pref/言語/フォント/Spaces/mods を宣言的に追加する。

**Architecture:** `home-manager/desktop/zen/default.nix` の `programs.zen-browser.profiles.default` を拡張する単一ファイル変更。検証は `nix` での eval（ビルド可否）と `home-manager switch` 後の目視確認で行う。Nix の宣言的設定のため失敗テストは書かず、「eval が通る」「switch が適用される」「Zen 上で値が反映される」を成功基準とする。

**Tech Stack:** Nix flake, home-manager, zen-browser-flake (beta module)

## Global Constraints

- 編集対象は Nix ソースのみ（`home-manager/desktop/zen/default.nix`）。`~` 配下の live ファイルは手編集しない。
- 有効ホスト: cachyos（`home-manager switch --flake .#cachyos`）。
- pref のキーは **必ずダブルクォート**で囲む（zen-browser-flake の仕様。ネスト表記は使わない）。
- `spacesForce = true` は既存 `zen-sessions.jsonlz4` を上書きする。switch 前に **Zen を完全終了**すること。
- 既存の `browser.tabs.warnOnClose` と `bookmarks` は維持する。
- フォントは cachyos に導入済みの実在フォント名のみ使用: `Noto Serif CJK JP` / `Noto Sans CJK JP` / `UDEV Gothic` / `Inter` / `JetBrainsMono Nerd Font`。

---

### Task 1: settings（pref / 言語 / フォント）を追加

**Files:**
- Modify: `home-manager/desktop/zen/default.nix`

**Interfaces:**
- Consumes: `inputs.zen-browser.homeModules.beta` が提供する `programs.zen-browser.profiles.default.settings`（attrset、キーは pref 名の文字列）。
- Produces: 拡張された `settings` attrset。Task 2 は同じ `profiles.default` 直下に `spacesForce` / `spaces` / `mods` を追加する。

- [ ] **Step 1: `settings` ブロックを拡張**

`home-manager/desktop/zen/default.nix` の `settings = { "browser.tabs.warnOnClose" = false; };` を、以下の `settings` ブロックに置き換える（ファイル全体は最終的に Task 2 完了時点で下記「最終形」になる。本タスクでは `spacesForce`/`spaces`/`mods` はまだ追加しない）。

```nix
{ inputs, ... }:
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;
    profiles.default = {
      settings = {
        "browser.tabs.warnOnClose" = false;

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

        # 言語（Accept-Language ヘッダのみ）
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
      bookmarks = import ./bookmarks.nix;
    };
  };
}
```

- [ ] **Step 2: eval（ビルド可否）を検証**

Run: `nix build .#homeConfigurations.cachyos.activationPackage --no-link 2>&1 | tail -20`
Expected: エラーなく完了（ビルド成功）。pref のクォート漏れや型エラーがあればここで失敗する。

- [ ] **Step 3: コミット**

```bash
git add home-manager/desktop/zen/default.nix
git commit -m "feat(zen): add pref/language/font settings"
```

---

### Task 2: spaces と mods を追加

**Files:**
- Modify: `home-manager/desktop/zen/default.nix`

**Interfaces:**
- Consumes: Task 1 で拡張済みの `profiles.default`（`settings` / `bookmarks` を持つ）。
- Produces: 同 attrset 直下に `spacesForce = true;`、`spaces`（attrset）、`mods`（文字列リスト）を追加した最終形。

- [ ] **Step 1: `spacesForce` / `spaces` / `mods` を追加**

`profiles.default` 直下（`bookmarks` の行の前後どちらでもよい）に以下を追加し、ファイルを下記「最終形」にする。

```nix
{ inputs, ... }:
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;
    profiles.default = {
      settings = {
        "browser.tabs.warnOnClose" = false;

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

        # 言語（Accept-Language ヘッダのみ）
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

      spacesForce = true;
      spaces = {
        "Personal" = {
          id = "5d4c9e3d-e72a-4bd3-9c28-a0890768ded1";
          position = 1000;
          icon = "🏠";
        };
        "Dev" = {
          id = "e3e428d8-c7e8-4d3b-9e29-d10aa3f80cae";
          position = 2000;
          icon = "💻";
        };
      };

      mods = [
        "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
        "253a3a74-0cc4-47b7-8b82-996a64f030d5" # Floating History
        "803c7895-b39b-458e-84f8-a521f4d7a064" # Hide Inactive Workspaces
        "906c6915-5677-48ff-9bfc-096a02a72379" # Floating Status Bar
      ];

      bookmarks = import ./bookmarks.nix;
    };
  };
}
```

- [ ] **Step 2: eval（ビルド可否）を検証**

Run: `nix build .#homeConfigurations.cachyos.activationPackage --no-link 2>&1 | tail -20`
Expected: エラーなく完了。

- [ ] **Step 3: コミット**

```bash
git add home-manager/desktop/zen/default.nix
git commit -m "feat(zen): declare Personal/Dev spaces and UI mods"
```

---

### Task 3: 適用と目視検証

**Files:** （変更なし。実機適用と確認のみ）

**Interfaces:**
- Consumes: Task 2 完了後の `default.nix`。

- [ ] **Step 1: Zen を完全終了**

`spacesForce = true` が `zen-sessions.jsonlz4` を上書きするため、Zen を起動したまま switch すると壊れる。Zen のウィンドウ・プロセスを全て閉じる。

Run: `pgrep -af zen || echo "zen not running"`
Expected: `zen not running`（プロセスが残っていれば終了させてから再実行）

- [ ] **Step 2: switch を適用**

Run: `home-manager switch --flake .#cachyos`
Expected: `Activating ...` まで完了しエラーなし。

- [ ] **Step 3: Zen を再起動して目視検証**

以下を確認する:
1. `about:config` で `zen.view.compact.hide-tabbar` = `true`、`intl.accept_languages` = `ja,en-US,en` になっている。
2. サイドバーに Space `Personal`（🏠）と `Dev`（💻）が出ている。
3. UI mod が効いている（新規タブで Top Sites が非表示など）。mod 反映にはブラウザ再起動が必要。
4. 日本語ページの本文が Noto Sans CJK JP、`<pre>`/等幅要素が UDEV Gothic で表示される。

- [ ] **Step 4: live と source の整合を確認**

Run: `readlink -f ~/.zen/* 2>/dev/null | head; echo "---"; git -C $(git rev-parse --show-toplevel) status --short`
Expected: live ファイルは Nix store の symlink。リポジトリに未コミットの変更が残っていない（Task 1/2 でコミット済み）。
