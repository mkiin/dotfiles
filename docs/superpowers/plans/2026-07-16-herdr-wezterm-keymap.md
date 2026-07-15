# herdr キーマップ wezterm 整合 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** herdr のキー割り当てを wezterm の `LEADER+文字` に一致させ、`ctrl+alt` chord を全廃し、`q`/detach の衝突を解消する。

**Architecture:** `home-manager/cli/herdr/default.nix` の Nix `settings.keys` テーブルを書き換えて `~/.config/herdr/config.toml` を生成する。設定ファイルは生成物なので直接編集しない。検証は Nix ビルド（構文・deadnix）→ home-manager switch（生成物反映）→ 実機で分割の向き確認、の順。

**Tech Stack:** Nix (home-manager, `pkgs.formats.toml`), herdr TOML config, Markdown。

## Global Constraints

- 対象ファイルは2つのみ: `home-manager/cli/herdr/default.nix` と `home-manager/cli/herdr/MANUAL.md`。テーマ・UI 設定は触らない。
- 相対パスで親を遡る `../` 参照を書かない（このリポジトリの禁止事項）。今回は同一ディレクトリ内なので該当しないが厳守。
- コメントは「なぜ」を1〜2行のみ。逐条コメント禁止。
- Nix 変更後は `nix run .#fmt -- --fail-on-change` を通す（deadnix / 整形）。
- prefix は `ctrl+b` 据え置き。CapsLock は herdr に届かないため wezterm と一致不可。
- WSL 反映コマンド: `nix run nixpkgs#home-manager -- switch --flake .#mkiin@wsl`。
- キー割り当ての正典は `herdr --default-config` の `[keys]` セクション。アクション名はそこに存在するものだけを使う。

## キー割り当て最終形（正典）

herdr アクション名 → 割り当てる文字列（TOML の値）:

| アクション            | 値                                                                  |
| --------------------- | ------------------------------------------------------------------- |
| `focus_pane_left`     | `"prefix+h"`                                                        |
| `focus_pane_down`     | `"prefix+j"`                                                        |
| `focus_pane_up`       | `"prefix+k"`                                                        |
| `focus_pane_right`    | `"prefix+l"`                                                        |
| `navigate_pane_left`  | `"h"`                                                               |
| `navigate_pane_down`  | `"j"`                                                               |
| `navigate_pane_up`    | `"k"`                                                               |
| `navigate_pane_right` | `"l"`                                                               |
| `new_tab`             | `"prefix+n"`                                                        |
| `close_tab`           | `"prefix+q"`                                                        |
| `previous_tab`        | `"prefix+shift+h"`                                                  |
| `next_tab`            | `"prefix+shift+l"`                                                  |
| `split_vertical`      | `"prefix+v"`（★向き検証。上下でなければ `split_horizontal` と入替） |
| `split_horizontal`    | `"prefix+s"`（★向き検証。左右でなければ `split_vertical` と入替）   |
| `close_pane`          | `"prefix+m"`                                                        |
| `zoom`                | `"prefix+z"`                                                        |
| `resize_mode`         | `"prefix+r"`                                                        |
| `detach`              | `"prefix+d"`                                                        |

`switch_tab`（`prefix+1..9`）・`edit_scrollback`（`prefix+e`）は herdr 既定のままで wezterm と一致するので **明示指定しない**（default-config に任せる）。

---

### Task 1: herdr の split 向きとアクション名を実機で確定する

計画のコードを書く前に、`split_vertical`/`split_horizontal` がどちらの見た目（左右／上下）を作るかを確定させる。ここが唯一の未知。実機の herdr で確認する。

**Files:**

- 変更なし（調査タスク）

- [ ] **Step 1: 現行 config で herdr を起動して分割を試す**

WSL の端末で:

```bash
herdr
```

herdr 内で現行キー（`ctrl+b` → `v`）を押して分割し、**画面が左右に割れるか上下に割れるか**を目視する。続けて `ctrl+b` → `-`（minus = `split_horizontal`）でもう一方を確認する。

- [ ] **Step 2: 対応を記録する**

観測結果を次の形で控える:

- `split_vertical`（現 `prefix+v`）→ ( 左右 / 上下 ) のどちらか
- `split_horizontal`（現 `prefix+minus`）→ ( 左右 / 上下 ) のどちらか

**判定ルール（wezterm 基準）:**

- wezterm は `s`=左右, `v`=上下。
- **もし `split_vertical` が上下なら**: Task 2 の割り当ては計画どおり（`split_vertical="prefix+v"`, `split_horizontal="prefix+s"`）。
- **もし `split_vertical` が左右なら**: 入れ替える（`split_vertical="prefix+s"`, `split_horizontal="prefix+v"`）。

この判定結果を Task 2 に持ち込む。コミットは無し（調査のみ）。

---

### Task 2: default.nix の keys を書き換える

**Files:**

- Modify: `home-manager/cli/herdr/default.nix`（`settings.keys` ブロック全体、現状 8-57 行）

**Interfaces:**

- Consumes: Task 1 の split 向き判定（`prefix+v` を上下・`prefix+s` を左右に割り当てる向き）。
- Produces: `~/.config/herdr/config.toml` の `[keys]` セクション（Task 4 の実機検証が読む）。

- [ ] **Step 1: `keys` ブロックを差し替える**

`home-manager/cli/herdr/default.nix` の `keys = { ... };`（現状の `focus_pane_*` の二刀流〜`zoom` まで）を次で丸ごと置換する。**split の2行は Task 1 が「`split_vertical`＝左右」と判定した場合のみ `prefix+s` と `prefix+v` を入れ替える**こと。

```nix
    keys = {
      # prefix→単一文字を wezterm(LEADER+文字) に一致させる。chord は全廃。
      focus_pane_left = "prefix+h";
      focus_pane_down = "prefix+j";
      focus_pane_up = "prefix+k";
      focus_pane_right = "prefix+l";

      # navigate モードは素の hjkl（prefix+ 不可のフィールド）
      navigate_pane_left = "h";
      navigate_pane_down = "j";
      navigate_pane_up = "k";
      navigate_pane_right = "l";

      new_tab = "prefix+n";
      # q は wezterm=タブを閉じる。detach は tmux 定番の prefix+d へ退避し衝突回避。
      close_tab = "prefix+q";
      detach = "prefix+d";
      previous_tab = "prefix+shift+h";
      next_tab = "prefix+shift+l";

      # wezterm 基準: s=左右, v=上下。Task 1 で向きが逆と判明したら s/v を入替。
      split_horizontal = "prefix+s";
      split_vertical = "prefix+v";

      close_pane = "prefix+m";
      zoom = "prefix+z";
      resize_mode = "prefix+r";
    };
```

- [ ] **Step 2: Nix の整形・deadnix を通す**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なし（exit 0）。差分が出たら整形結果を取り込んで再実行し、0 にする。

- [ ] **Step 3: WSL の home-manager をビルドして構文検証する**

Run: `nix build .#homeConfigurations."mkiin@wsl".activationPackage --no-link`
Expected: エラーなくビルド成功。TOML 生成（`tomlFormat.generate`）まで評価が通ることを確認する。

- [ ] **Step 4: コミット**

```bash
git add home-manager/cli/herdr/default.nix
git commit -m "feat(herdr): キーマップを wezterm に整合、ctrl+alt chord 全廃・q/detach 衝突解消"
```

---

### Task 3: MANUAL.md を新キーへ更新する

**Files:**

- Modify: `home-manager/cli/herdr/MANUAL.md`

**Interfaces:**

- Consumes: Task 2 の最終キー割り当て（split の向きも Task 1 判定を反映）。

- [ ] **Step 1: プレフィックス説明（2節）から chord 併設の記述を削除**

現状の「この設定では、プレフィックスに加えて `ctrl+alt` の直接 chord を併設しています…」の段落を削除し、次の1文に置換する:

```markdown
この設定では prefix→単一文字の操作を、普段使いの wezterm の `LEADER+文字` に一致させています（chord は使いません）。
```

- [ ] **Step 2: 「3. vim chord 早見表」を新キー表へ置換**

節タイトルを `## 3. キー早見表（この設定）` に変え、表を次で置換する:

```markdown
| 操作                      | キー（prefix = `ctrl+b`）       |
| ------------------------- | ------------------------------- |
| ペイン移動（左/下/上/右） | `ctrl+b` → `h`/`j`/`k`/`l`      |
| 分割（左右 / 上下）       | `ctrl+b` → `s` / `ctrl+b` → `v` |
| ペインを閉じる            | `ctrl+b` → `m`                  |
| ズーム                    | `ctrl+b` → `z`                  |
| リサイズモード            | `ctrl+b` → `r`                  |
| 新しいタブ                | `ctrl+b` → `n`                  |
| タブを閉じる              | `ctrl+b` → `q`                  |
| 前/次のタブ               | `ctrl+b` → `H` / `ctrl+b` → `L` |
| タブ 1〜9 へ              | `ctrl+b` → `1`..`9`             |
| detach                    | `ctrl+b` → `d`                  |

navigate モード（ワークスペース/ペインをキーボードで辿るモード）では素の `h`/`j`/`k`/`l` で移動します。
```

- [ ] **Step 3: 「4. まず覚える5つ」を新キーへ更新**

表を次で置換する:

```markdown
| やりたいこと                   | キー                            |
| ------------------------------ | ------------------------------- |
| 新しいタブ                     | `ctrl+b` → `n`                  |
| 分割（左右/上下）              | `ctrl+b` → `s` / `ctrl+b` → `v` |
| ペイン間移動                   | `ctrl+b` → `h`/`j`/`k`/`l`      |
| ワークスペース選択             | `ctrl+b` → `w`                  |
| detach（全部動かしたまま離脱） | `ctrl+b` → `d`                  |
```

- [ ] **Step 4: 「5. コピーモード（vim 操作）」節を実態へ書き換える**

存在しない vim コピーモードの記述を削除し、節を次で置換する:

```markdown
## 5. スクロールとコピー

herdr にキーボードの vim 式コピーモードはありません。スクロールとコピーは次で行います。

- スクロール: マウスホイール。
- コピー: マウスのドラッグ／ダブルクリックで選択（`copy_on_select`）。
- スクロールバックを腰を据えて見る／コピーする: `ctrl+b` → `e`（`edit_scrollback`）で外部エディタに開く。
```

- [ ] **Step 5: detach 記述の整合を取る**

「8. detach / reattach とトラブル時」の `detach: ctrl+b → q` を `detach: ctrl+b → d` に直す。他に旧キー（`c` 新タブ・`v`/`-` 分割・`q` detach）が本文へ残っていないか grep で確認する:

Run: `grep -nE 'ctrl\+b.*→.*[cq]|prefix\+q|ctrl\+alt' home-manager/cli/herdr/MANUAL.md`
Expected: 旧キーの残骸がヒットしない（ヒットしたら該当箇所を新キーへ修正）。

- [ ] **Step 6: コミット**

```bash
git add home-manager/cli/herdr/MANUAL.md
git commit -m "docs(herdr): MANUAL を新キーへ更新・存在しないコピーモード節を実態に修正"
```

---

### Task 4: 実機反映と ★検証事項の確認

**Files:**

- 変更なし（反映・検証タスク。不一致が見つかった場合のみ Task 2/3 へ戻る）

**Interfaces:**

- Consumes: Task 2 で生成される `config.toml`。

- [ ] **Step 1: WSL に反映する**

Run: `nix run nixpkgs#home-manager -- switch --flake .#mkiin@wsl`
Expected: activation 成功。

- [ ] **Step 2: 生成された config を確認する**

Run: `grep -nE 'split_|close_tab|detach|new_tab|previous_tab|next_tab' ~/.config/herdr/config.toml`
Expected: Task 2 の割り当てどおりの値が出力される。

- [ ] **Step 3: herdr を再読み込みして実挙動を確認する**

```bash
herdr server reload-config
```

herdr 内で次を実機確認する:

- `ctrl+b` → `s` が**左右**分割、`ctrl+b` → `v` が**上下**分割になっているか。逆なら Task 2 Step 1 に戻り `split_horizontal`/`split_vertical` の値を入れ替えて再コミット→再 switch。
- `ctrl+b` → `q` で**タブが閉じる**（detach しない）こと。
- `ctrl+b` → `d` で**detach** し、`herdr` で再接続できること。
- `ctrl+b` → `n` で新タブ、`ctrl+b` → `H`/`L` でタブ移動、`ctrl+b` → `m` でペインを閉じること。

- [ ] **Step 4: 不一致があれば修正、なければ完了**

向き入替が必要だった場合のみ、Task 2 の `keys` を修正して `nix run .#fmt -- --fail-on-change` → ビルド → コミット → 再 switch。MANUAL の s/v 説明も実挙動に一致しているか最終確認する（Task 3 の表は「s=左右/v=上下」で書いてあるので、入替時は MANUAL 側の記述変更は不要 = 常に「見た目基準」で一致する）。

---

## Self-Review

- **Spec coverage:**
  - keys 書き換え（chord 全廃・new_tab/close_tab/tab nav/split/close_pane/detach）→ Task 2 ✓
  - navigate モード据え置き → Task 2 の `navigate_pane_*` 維持 ✓
  - MANUAL 全面更新・コピーモード節削除 → Task 3 ✓
  - 反映と ★検証（分割の向き・q/d）→ Task 1（事前調査）+ Task 4（反映後確認）✓
  - 非目標（prefix 変更・vim コピー化・テーマ）に触れていない ✓
- **Placeholder scan:** TBD/TODO 無し。split 向きは「調査タスク＋入替ルール」で具体化済み（未定ではなく分岐指示）。
- **Type consistency:** アクション名は `herdr --default-config` の `[keys]` に存在するものだけ使用（`focus_pane_*`/`navigate_pane_*`/`new_tab`/`close_tab`/`previous_tab`/`next_tab`/`split_vertical`/`split_horizontal`/`close_pane`/`zoom`/`resize_mode`/`detach`）。`switch_tab`/`edit_scrollback` は既定一致のため未指定。
