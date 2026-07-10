# pyprland fcitx5_switcher 実装プラン

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** wezterm と ghostty にフォーカスするたび fcitx5 の IME を自動的にオフにする。

**Architecture:** fcitx5 の `ShareInputState` を `No` に変えて IME 状態をプログラムごとに独立させたうえで、pyprland 同梱の `fcitx5_switcher` プラグインを有効化し、Hyprland の `activewindowv2` イベントでターミナルの window class を検出して `fcitx5-remote -c` を発行する。二つの変更は別コミットに分け、fcitx5 側の効果を実機で確認してから pyprland 側を入れる。

**Tech Stack:** Nix (home-manager), fcitx5 5.x, pyprland 3.4.2, Hyprland

## Global Constraints

- 設計ドキュメントは `docs/superpowers/specs/2026-07-10-pyprland-fcitx5-switcher-design.md`。
- パッケージ宣言は追加しない。`pyprland` は `home-manager/desktop/packages.nix` に、`fcitx5-remote` は `nixos/desktop/fcitx5` の `i18n.inputMethod` 経由で既に PATH 上にある。機能ディレクトリの `default.nix` に `home.packages` を書いてはならない。
- コメントは「なぜそうしたか」だけを 1〜2 行で書く。設定項目を日本語で言い換えるだけのコメントは書かない。
- `../` で親ディレクトリへ遡る相対パス参照を書かない。
- Nix を変更したら `nix run .#build` と `nix run .#fmt -- --fail-on-change` を両方通す。
- ターミナル以外のアプリケーションの IME 状態には介入しない。`active_classes` / `active_titles` / `inactive_titles` は記述しない。
- 自動テストは書かない。実機の手動確認を受け入れ条件とする。

---

### Task 1: fcitx5 の IME 状態をプログラムごとに独立させる

`ShareInputState=All` は IME のオン/オフ状態をシステム全体で 1 個だけ持つ設定である。このままだと Task 2 で入れるプラグインがターミナルで発行する `fcitx5-remote -c` が唯一のグローバル状態を書き換え、ターミナルを一瞬覗いただけで他のアプリケーションの IME まで落ちる。先にここを直す。

**Files:**

- Modify: `home-manager/desktop/fcitx5/config:46`

**Interfaces:**

- Consumes: なし
- Produces: `ShareInputState=No`。Task 2 のプラグインは、この設定が効いていることを前提に「ターミナルだけをオフにする」挙動を実現する。

- [ ] **Step 1: 変更前の挙動を記録する**

Zen（または任意の GUI アプリ）にフォーカスして `Alt_R` を押し、IME をオンにする。その状態で wezterm にフォーカスを移し、wezterm の中で次を実行する。

```bash
fcitx5-remote
```

引数なしの `fcitx5-remote` は現在の IME 状態を数値で標準出力に返す。`0` が非アクティブ、`2` がアクティブ。

Expected: `2`（状態がグローバルに共有されているため、Zen でオンにした状態がターミナルにも付いてきている）

ここで `0` が返る場合、想定と異なる。`ShareInputState` 以外の要因が働いているので、先に進まず状況を報告する。

- [ ] **Step 2: `ShareInputState` を `No` に変える**

`home-manager/desktop/fcitx5/config` の 45〜46 行目を次のように書き換える。既存のコメント行「# 入力状態を共有する」は設定項目を言い換えているだけなので、なぜ `No` なのかを述べるコメントに差し替える。

変更前:

```ini
# 入力状態を共有する
ShareInputState=All
```

変更後:

```ini
# pyprland の fcitx5_switcher がターミナルで -c を投げるため、状態がグローバル 1 個だと
# 他アプリの IME まで巻き添えで落ちる。プログラムごとに独立させる。
ShareInputState=No
```

- [ ] **Step 3: 反映する**

```bash
nix run .#switch
```

Expected: エラーなく完了する。

`config` は `xdg.configFile` でリンクされており、fcitx5 は起動時にしか読まないので、続けて fcitx5 を再起動する。

```bash
systemctl --user restart fcitx5
```

- [ ] **Step 4: プログラム識別が効いているか確認する**

これが本タスクの受け入れ条件である。fcitx5 が wezterm と ghostty を別プログラムとして識別できるかは自明ではない。GTK や Qt のアプリケーションは IM モジュール経由でプログラム名を渡すが、wezterm と ghostty は Wayland の text-input プロトコルを直接使うため、プログラム名が fcitx5 に届かない可能性がある。

Step 1 と同じ操作をする。Zen にフォーカスして `Alt_R` で IME をオンにし、wezterm にフォーカスを移して `fcitx5-remote` を実行する。

Expected: `0`

`0` が返れば、wezterm が Zen とは独立した IME 状態を持っている。ghostty でも同じ確認をする。

```bash
ghostty
```

起動した ghostty の中で `fcitx5-remote` を実行する。

Expected: `0`

- [ ] **Step 5: 識別が効いていない場合の切り分け**

Step 4 で `2` が返った場合のみ、このステップを実行する。`0` が返っていればスキップする。

fcitx5 のログを上げて、InputContext に紐づく program 名が取れているかを直接見る。

```bash
systemctl --user stop fcitx5
FCITX_LOG_RULES='default=5' fcitx5 -d --verbose '*=5' 2>&1 | tee /tmp/fcitx5.log
```

この状態で Zen と wezterm のあいだでフォーカスを往復させ、`/tmp/fcitx5.log` に program 名が記録されているかを確認する。program が空文字のままなら識別できていない。

確認が終わったら通常の起動に戻す。

```bash
systemctl --user start fcitx5
```

識別できていないことが確定した場合、Step 2 の変更を `ShareInputState=All` に戻し、コメントも元の「# 入力状態を共有する」に戻す。Task 2 の設定内容は変わらない。この場合、ターミナルを覗くと他のアプリケーションの IME も落ちるという副作用を受け入れることになる（落ちた IME は `Alt_R` で戻せる）。ターミナルがデフォルトで IME オフになるという目的そのものは達成される。

どちらの結論になったかを、次のタスクに進む前に報告する。

- [ ] **Step 6: フォーマットとビルドを通す**

```bash
nix run .#fmt -- --fail-on-change
nix run .#build
```

Expected: 両方ともエラーなく完了する。

- [ ] **Step 7: コミット**

Step 5 で `All` に戻した場合は、コミットする変更がないのでこのステップをスキップし、Task 2 に進む。

```bash
git add home-manager/desktop/fcitx5/config
git commit -m "fix(fcitx5): IME 状態をプログラムごとに独立させる"
```

---

### Task 2: pyprland の fcitx5_switcher でターミナルの IME をオフにする

**Files:**

- Modify: `home-manager/desktop/pyprland/default.nix`

**Interfaces:**

- Consumes: Task 1 の `ShareInputState=No`（識別が効かず `All` に戻した場合も、本タスクの変更内容は同一）
- Produces: `~/.config/pypr/config.toml` の `[fcitx5_switcher]` セクション。`inactive_classes` に wezterm と ghostty の window class を列挙する。

- [ ] **Step 1: ghostty の window class を実測する**

設計時点で wezterm の class が `org.wezfurlong.wezterm` であることは `hyprctl clients` で確認済みだが、ghostty は未確認である。推測で設定を書くと黙って効かない設定ができあがるので、先に実測する。

ghostty を起動した状態で次を実行する。

```bash
hyprctl clients -j | jq -r '.[] | .class'
```

Expected: 出力の中に `com.mitchellh.ghostty` と `org.wezfurlong.wezterm` の両方が含まれる。

ghostty の class が `com.mitchellh.ghostty` と異なっていた場合、Step 2 の設定にはこの実測値をそのまま書く。以降のステップの `com.mitchellh.ghostty` を実測値に読み替える。

- [ ] **Step 2: プラグインを有効化して設定を書く**

`home-manager/desktop/pyprland/default.nix` の `xdg.configFile."pypr/config.toml".text` を編集する。

まず `plugins` リストに `"fcitx5_switcher"` を追加する。

変更前:

```nix
    plugins = [
      "wallpapers",
      "workspaces_follow_focus",
      "toggle_special",
      "lost_windows",
    ]
```

変更後:

```nix
    plugins = [
      "wallpapers",
      "workspaces_follow_focus",
      "toggle_special",
      "lost_windows",
      "fcitx5_switcher",
    ]
```

次に、`[toggle_special]` セクションの後、末尾の scratchpads に関するコメントの前に、次のセクションを追加する。

```nix
    # ターミナルでは日本語をほぼ打たないので、フォーカスするたび無条件で IME を落とす。
    # active_classes は空のまま。IME を自動オンにするアプリは決めていない。
    [fcitx5_switcher]
    inactive_classes = ["org.wezfurlong.wezterm", "com.mitchellh.ghostty"]
```

`active_classes`、`active_titles`、`inactive_titles` は記述しない。プラグインの既定値である空リストに任せる。

- [ ] **Step 3: フォーマットとビルドを通す**

```bash
nix run .#fmt -- --fail-on-change
nix run .#build
```

Expected: 両方ともエラーなく完了する。

- [ ] **Step 4: 反映して daemon の再起動を確認する**

```bash
nix run .#switch
```

pyprland の systemd user service には `X-Restart-Triggers` として `config.toml` が既に登録されている。生成された config の変化を検出して daemon が自動的に再起動するので、手動での再起動は不要である。

```bash
systemctl --user status pyprland
```

Expected: `active (running)` であり、直近の起動時刻が `nix run .#switch` の実行後になっている。

プラグインが読み込まれたことをログで確認する。

```bash
journalctl --user -u pyprland -n 30 --no-pager
```

Expected: `fcitx5_switcher` の読み込みに失敗した旨のエラーが出ていない。

- [ ] **Step 5: ターミナルで IME がオフになることを確認する**

Zen にフォーカスして `Alt_R` で IME をオンにする。wezterm にフォーカスを移し、wezterm の中で次を実行する。

```bash
fcitx5-remote
```

Expected: `0`

ghostty でも同じ確認をする。

Expected: `0`

Task 1 で `ShareInputState=No` が効いていた場合、Zen に戻ると IME はオンのままである。`All` に戻した場合、Zen の IME も落ちている。どちらであるかは Task 1 の結論から予測でき、その予測どおりであることを確認する。

- [ ] **Step 6: 手動でオンにしても戻ってくればオフになることを確認する**

これが設計で定めた「毎回強制オフ」の挙動である。

wezterm にフォーカスした状態で `Alt_R` を押す。

```bash
fcitx5-remote
```

Expected: `2`

Zen にフォーカスを移し、そのまま wezterm に戻る。

```bash
fcitx5-remote
```

Expected: `0`

- [ ] **Step 7: コミット**

```bash
git add home-manager/desktop/pyprland/default.nix
git commit -m "feat(pyprland): ターミナルで IME を自動オフにする"
```

---

## 完了条件

- wezterm と ghostty にフォーカスするたび `fcitx5-remote` が `0` を返す。
- ターミナル内で `Alt_R` を押して `2` にしても、他のウィンドウを経由して戻ると `0` に戻る。
- `nix run .#build` と `nix run .#fmt -- --fail-on-change` が通る。
- Task 1 の Step 4 の結果（`ShareInputState=No` が効いたか、`All` に戻したか）が報告されている。
