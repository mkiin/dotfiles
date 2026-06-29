# waybar 特殊ワークスペースのシンボル表示 実装プラン

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** super+s で開く特殊ワークスペース(`special:magic`)を、waybar の ws モジュールに数字とは異なるシンボルのボタンとして表示する。

**Architecture:** waybar の再ビルドは不要。`hyprland/workspaces` モジュールの `format` を `{icon}` 化し、`format-icons` で数字 1〜5 はそのまま、特殊ワークスペースのみ別グリフにマッピングする(waybar の selectIcon 解決順 urgent→active→**special**→名前 を利用。`active` を定義しないことで特殊ワークスペースが `special` キーに確実に一致する)。CSS で `.special` ボタンを装飾し数字ボタンと区別する。

**Tech Stack:** waybar v0.15.0 (GTK4) / Hyprland (configType=lua) / Nix (home-manager as NixOS module) / matugen 生成カラー (Material Design 3 トークン)

## Global Constraints

- 対象ファイルは2つのみ: `home-manager/desktop/waybar/config.json`、`home-manager/desktop/waybar/styles/capsule-nobg.css`
- waybar の再ビルド・overlay は行わない(クリック修正は今回スコープ外。`docs/superpowers/specs/2026-06-29-waybar-special-workspace-symbol-design.md` 参照)
- `config.json` は純 JSON(コメント不可)。`programs.waybar.settings = [ importJSON ./config.json ]` でビルド時にベイクされる → 反映には `sudo nixos-rebuild switch --flake .#nixos` + waybar 再起動が必要
- `styles/capsule-nobg.css` は `lnk` シンボリックリンク管理。**live の symlink はメインチェックアウト (`~/ghq/github.com/mkiin/dotfiles`) を指す**ため、worktree 内の編集は merge するまで live に反映されない
- カラートークンは matugen 生成の `@tertiary` / `@on_tertiary` を使用(`~/.config/waybar/colors.css` に実在確認済み)
- 既存の数字ワークスペース 1〜5 の表示・アクティブ強調(CSS `.active`)を壊さないこと
- 作業は worktree `worktree-waybar-special-ws` 内。コミット粒度は小さく

---

### Task 1: config.json — 特殊ワークスペースの表示とシンボルマッピング

**Files:**

- Modify: `home-manager/desktop/waybar/config.json:90-101`(`hyprland/workspaces` ブロック)

**Interfaces:**

- Consumes: なし(独立した設定変更)
- Produces: `hyprland/workspaces` が `format: "{icon}"`、`show-special: true`、`special-visible-only: true`、`format-icons` に `"special"` キーを持つ状態。Task 2 の CSS は `show-special` により生成される `button.special` を装飾する

- [ ] **Step 1: `hyprland/workspaces` ブロックを書き換える**

`home-manager/desktop/waybar/config.json` の現状(90〜101行目):

```json
  "hyprland/workspaces": {
    "format": "{id}",
    "on-click": "activate",
    "format-icons": {
      "active": "{id}",
      "default": "",
      "urgent": ""
    },
    "persistent-workspaces": {
      "*": [1, 2, 3, 4, 5]
    }
  },
```

を、次に置き換える:

```json
  "hyprland/workspaces": {
    "format": "{icon}",
    "on-click": "activate",
    "show-special": true,
    "special-visible-only": true,
    "format-icons": {
      "1": "1",
      "2": "2",
      "3": "3",
      "4": "4",
      "5": "5",
      "special": "󰓎"
    },
    "persistent-workspaces": {
      "*": [1, 2, 3, 4, 5]
    }
  },
```

変更の要点:

- `format` を `{id}` → `{icon}`(format-icons を有効化するため必須)
- `show-special` / `special-visible-only` を追加(特殊ワークスペースが可視=アクティブな時のみボタン表示)
- 旧 `format-icons` の `"active": "{id}"` を**削除**(これがあると特殊ワークスペースがアクティブ時に `active` キーへ先に一致し `special` に届かない)
- 旧 `"default": ""` を**削除**(空文字だと数字が消える)。数字 1〜5 は名前一致で表示
- `"special"` に魔法/特殊を示すグリフ `󰓎`(nf-md-star)を仮置き(Task 3 で実機確認し必要なら差し替え)
- `on-click: "activate"` は現状維持(v0.15.0 では無視されるが無害。クリック修正は別途リリース待ち)

- [ ] **Step 2: JSON 構文を検証する**

Run: `python3 -m json.tool home-manager/desktop/waybar/config.json > /dev/null && echo VALID`
Expected: `VALID`(構文エラーがあれば例外が出る)

- [ ] **Step 3: format-icons に `active` / 空 `default` が残っていないことを確認する**

Run: `python3 -c "import json;d=json.load(open('home-manager/desktop/waybar/config.json'));fi=d['hyprland/workspaces']['format-icons'];print('active' in fi, fi.get('default'), d['hyprland/workspaces']['format'], d['hyprland/workspaces'].get('show-special'), fi.get('special'))"`
Expected: `False None {icon} True 󰓎`
(= active キー無し / default 無し / format は {icon} / show-special 有効 / special グリフ有り)

- [ ] **Step 4: コミット**

```bash
git add home-manager/desktop/waybar/config.json
git commit -m "feat(waybar): show special workspace as symbol via format-icons"
```

---

### Task 2: capsule-nobg.css — 特殊ワークスペースボタンの装飾

**Files:**

- Modify: `home-manager/desktop/waybar/styles/capsule-nobg.css`(Workspaces セクション、`button.urgent` ルールの直後 ≒165行目付近)

**Interfaces:**

- Consumes: Task 1 で `show-special` により生成される `#workspaces button.special`
- Produces: 特殊ワークスペースボタンが `@tertiary` 背景・`@on_tertiary` 文字色で表示され、数字ボタン(`@surface_container_highest` / アクティブは `@primary`)と視覚的に区別される

- [ ] **Step 1: `.special` ルールを追加する**

`home-manager/desktop/waybar/styles/capsule-nobg.css` の Workspaces セクション、既存の `.urgent` ルール:

```css
#workspaces button.urgent {
  background-color: @error;
  color: @on_error;
}
```

の**直後**に次を追加する(順序が重要: `.active` / `.urgent` より後に置くことで、特殊ワークスペースがアクティブで `.active` クラスも持つ場合に `.special` の色が勝つ):

```css
/* 特殊ワークスペース (super+s の special:magic)。show-special で出現する
 * button.special を tertiary 系で着色し数字ボタンと区別する。シンボル文字
 * 自体は config.json の format-icons "special" が供給する (GTK CSS は
 * グリフ注入不可のため装飾のみ担当)。 */
#workspaces button.special {
  color: @on_tertiary;
  background-color: @tertiary;
}
```

- [ ] **Step 2: ルールが `.active` / `.urgent` より後に置かれていることを確認する**

Run: `grep -n "button.active\|button.urgent\|button.special" home-manager/desktop/waybar/styles/capsule-nobg.css`
Expected: 行番号が `button.active` < `button.urgent` < `button.special` の順(special が最後)

- [ ] **Step 3: コミット**

```bash
git add home-manager/desktop/waybar/styles/capsule-nobg.css
git commit -m "style(waybar): add tertiary color for special workspace button"
```

---

### Task 3: ビルド検証・live反映・グリフ確定

**Files:**

- なし(検証・反映のみ。必要に応じて Task 1 の `"special"` グリフを1行修正)

**Interfaces:**

- Consumes: Task 1 / Task 2 のコミット
- Produces: 実機で動作確認済みの最終状態

- [ ] **Step 1: flake が評価できることを検証する(worktree内、switch しない)**

Run: `nixos-rebuild build --flake .#nixos 2>&1 | tail -5`
Expected: エラーなく `./result` が生成される(config.json の JSON / nix 評価が通ることの確認。`sudo` 不要。時間がかかる場合あり)
補足: 評価だけ素早く確認したい場合は
`nix eval --raw .#nixosConfigurations.nixos.config.home-manager.users.mkiin.xdg.configFile.\"waybar/config.json\".source 2>/dev/null || true`

- [ ] **Step 2: worktree のブランチをメインに反映する**

worktree の CSS symlink はメインチェックアウトを指すため、live 反映にはメインへの取り込みが必要。レビュー承認後に worktree ブランチをメイン(`main`)へマージするか、メインチェックアウトで cherry-pick する。
(この手順はレビュー/マージ運用に従う。マージ前に live 反映はできない)

- [ ] **Step 3: メインチェックアウトで switch する**

メインチェックアウト `~/ghq/github.com/mkiin/dotfiles` で:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

- [ ] **Step 4: waybar を再起動する**

config.json 変更は CSS ホットリロードでは反映されないため再起動する:

Run: `systemctl --user restart waybar`
Expected: エラーなく再起動(`systemctl --user status waybar` が active)

- [ ] **Step 5: 通常ワークスペースの表示を確認する**

ws モジュールに 1〜5 の数字が従来通り表示され、現在のワークスペースがアクティブ強調(幅広・`@primary`)されていることを目視確認する。
Expected: 数字 1〜5 が表示され見た目が従来と同じ

- [ ] **Step 6: 特殊ワークスペースのシンボルを確認する**

`super+s` を押して特殊ワークスペースをトグルする。
Expected: ws モジュールに数字とは別のシンボル(`󰓎`)のボタンが現れ、`@tertiary` 色で着色される。もう一度 `super+s` で閉じるとそのボタンが消える。

- [ ] **Step 7: グリフを確定する(必要な場合)**

Step 6 でグリフが豆腐(□)になる・見栄えが悪い場合、`config.json` の `format-icons.special` を別の Nerd Font グリフに変更する。候補例: `󰓏`(star-outline)、``(fa-star)、`󰮯`(circle)など。変更したら Step 3〜6 を再実行。
変更が発生した場合のコミット:

```bash
git add home-manager/desktop/waybar/config.json
git commit -m "feat(waybar): finalize special workspace glyph"
```

- [ ] **Step 8: 設計ドキュメントの未確定事項を解消済みにする(任意)**

`docs/superpowers/specs/2026-06-29-waybar-special-workspace-symbol-design.md` の「実機で確定する箇所」が解決済みであることを確認(本プランで `active` 非定義 + `special` キーに確定済み)。

---

## Self-Review

**Spec coverage(スペック各要件 → タスク対応):**

- 特殊ワークスペースをシンボル表示 → Task 1(`show-special` + `format-icons.special`)
- アクティブ時のみ表示 → Task 1(`special-visible-only`)
- 数字 1〜5 の表示・強調を維持 → Task 1(`active` 非定義で名前一致表示)+ Task 3 Step 5
- 数字ボタンと色で区別 → Task 2(`button.special` 着色)
- CSS でグリフ注入不可 → format-icons がグリフ供給、CSS は装飾(Task 1 + Task 2)
- クリック修正は対象外 → 本プランで一切触れず(Global Constraints に明記)
- 反映方法(switch + 再起動、CSS は lnk) → Task 3 Step 3〜4

**Placeholder scan:** TBD/TODO 等なし。各ステップに実コマンド・実コードを記載。グリフ差し替えは「条件付き分岐」であってプレースホルダではない(デフォルト値 `󰓎` を明示済み)。

**Type consistency:** CSS クラス名 `button.special` は waybar v0.15.0 が special ワークスペースに付与するクラス(`addOrRemoveClass(isSpecial(), "special")`)と一致。`format-icons` の `"special"` キーは selectIcon の `isSpecial()` 分岐と一致。カラートークン `@tertiary` / `@on_tertiary` は live colors.css に実在。
