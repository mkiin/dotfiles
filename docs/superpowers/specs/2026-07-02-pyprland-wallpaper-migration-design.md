# pyprland wallpapers 移行 設計書

- 日付: 2026-07-02
- 対象: `home-manager/desktop/` の壁紙まわり
- スコープ: **pyprland の wallpapers プラグインのみ**。monitors / scratchpads / workspaces_follow_focus 等の他プラグインは対象外（別タスク）。

## 目的

自作の壁紙スクリプト群（`init.sh` / `pick.sh` / `rotate.sh` / `thumb.sh`）を撤去し、
選択・回転・デーモン制御を pyprland `wallpapers` プラグインへ移行する。
色生成パイプライン（matugen + wallust）は温存し、pyprland の `post_command` として引き続き駆動する。

## スコープ外（今回やらないこと）

- matugen / wallust を pyprland の templates 機能で置換すること（大規模。quickshell/waybar/ghostty/wezterm/wlogout/lock の全テンプレ移植を要するため将来の別タスク）。
- hyprpaper への移行（awww の grow トランジション演出を失うため）。
- 壁紙選択ランチャー / 設定センター UI 本体の実装（別タスク）。本設計は「設定センターから transition を実行時変更できる下地」までを用意する。

## 決定事項（確定）

| 論点                                           | 決定                                                                                             |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| 色パイプライン                                 | matugen / wallust を維持（Level A）。pyprland は選択・回転・デーモンのみ                         |
| 壁紙セットのバックエンド                       | awww を維持（grow トランジション演出のため）                                                     |
| デーモン起動                                   | systemd ユーザーサービス（`awww-daemon` + `pyprland`）                                           |
| no-repeat シャッフル                           | 廃止（pyprland 純ランダムを許容）                                                                |
| restore-last                                   | 廃止（起動時は常にランダム）                                                                     |
| schedule ファイル                              | 廃止                                                                                             |
| thumb.sh                                       | 削除                                                                                             |
| notify                                         | 全廃                                                                                             |
| 回転 ON/OFF                                    | `pypr wall pause` / `pypr wall next`（keybind 割当）                                             |
| transition 系（type/fps/duration/step/bezier） | **実行時可変**。`hyprctl-state`(`state.env`) から `set.sh` が都度読む                            |
| interval（回転間隔）                           | 宣言的。変更は Nix 編集 + `nix run .#switch`                                                     |
| pyprland.toml の管理                           | **単一の読取専用シンボリックリンク**（`xdg.configFile.text` 生成。追加の可変ファイルは作らない） |

## アーキテクチャ

### 責務分担

| レイヤー              | 実装                                                                                                           |
| --------------------- | -------------------------------------------------------------------------------------------------------------- |
| デーモン              | systemd: `awww-daemon.service` + `pyprland.service`（After/Requires=awww-daemon）                              |
| 選択・回転            | pyprland `[wallpapers]`（純ランダム + `interval`）                                                             |
| 壁紙セット            | pyprland `command = set.sh [file]`（ラッパー。transition 系を `state.env` から読む）                           |
| 色生成 + 波及         | pyprland `post_command = post.sh [file]`（matugen + wallust → waybar/ghostty/hyprctl reload → last_wallpaper） |
| 回転 ON/OFF           | `pypr wall pause` / `pypr wall next`（keybind）                                                                |
| transition 実行時切替 | `hyprctl-state set AWWW_TRANSITION_*` → 次回転で反映（設定センター用）                                         |

### データフロー（起動時）

```
graphical-session.target
  └─ awww-daemon.service (起動)
       └─ pyprland.service (After/Requires=awww-daemon)
            └─ wallpapers プラグイン main_loop
                 ├─ ランダム選択
                 ├─ command:      set.sh [file]  → state.env の transition 系で awww img
                 └─ post_command: post.sh [file] → matugen + wallust(並列)
                                                    → waybar reload / ghostty SIGUSR2 / hyprctl reload
                                                    → last_wallpaper 記録
以降 interval 分ごとに繰り返し。手動は pypr wall next。
```

## コンポーネント詳細

### 1. 追加: `home-manager/desktop/pyprland/default.nix`

`home-manager/desktop/default.nix` の `imports` に `./pyprland` を追加。

責務:

- `home.packages` に `pyprland` を追加（keybind / 端末から `pypr` を使うため PATH に必要）。
- `xdg.configFile."pypr/config.toml".text`（下記）を生成 → 単一の読取専用 symlink。
  - 配置先は pyprland 3.x の推奨パス `~/.config/pypr/config.toml`。legacy の `~/.config/hypr/pyprland.toml` は起動時に移行警告が出るため使わない。
  - `path` と `command` / `post_command` の絶対パスは Nix 補間で埋める（`${dotfilesDir}` / `${config.home.homeDirectory}`）。`~` 展開に依存しない。
- systemd ユーザーサービス 2 つ（HM 形式。既存 `quickshell` / `mouse` サービスに倣う）。

生成する `pyprland.toml`（イメージ、パスは Nix 補間後の値）:

```toml
[pyprland]
plugins = ["wallpapers"]

[wallpapers]
path = "<dotfilesDir>/images/wallpaper"
interval = 30
extensions = ["jpg", "jpeg", "png", "webp"]
command = "<home>/.config/hypr/scripts/wallpaper/set.sh [file]"
post_command = "<home>/.config/hypr/scripts/wallpaper/post.sh [file]"
```

systemd サービス:

```nix
systemd.user.services.awww-daemon = {
  Unit = {
    Description = "awww wallpaper daemon";
    PartOf = [ "graphical-session.target" ];
    After = [ "graphical-session.target" ];
  };
  Service = {
    ExecStart = "${pkgs.awww}/bin/awww-daemon";
    Restart = "on-failure";
    RestartSec = 2;
  };
  Install.WantedBy = [ "graphical-session.target" ];
};

systemd.user.services.pyprland = {
  Unit = {
    Description = "pyprland daemon (wallpapers plugin)";
    PartOf = [ "graphical-session.target" ];
    After = [ "graphical-session.target" "awww-daemon.service" ];
    Requires = [ "awww-daemon.service" ];
  };
  Service = {
    ExecStart = "${pkgs.pyprland}/bin/pypr";
    Restart = "on-failure";
    RestartSec = 2;
  };
  Install.WantedBy = [ "graphical-session.target" ];
};
```

> `Requires`/`After` は「awww-daemon プロセス起動後に pypr を起動」を保証するが、awww の IPC ソケット ready までは保証しない。初回 `set.sh` がソケット未 ready で失敗しないよう、`set.sh` 側で短い `awww query` 待ちを入れる（下記）。

### 2. 新規: `scripts/wallpaper/set.sh`（pyprland `command`）

配置は既存スクリプトと同じ `home-manager/desktop/hyprland/scripts/wallpaper/`（`lnk ./scripts` で symlink 済み、編集可）。

役割: `[file]`（= `$1`）を受け取り、`hyprctl-state` から transition 系を読んで `awww img` を実行。

- 読むキー: `AWWW_TRANSITION_TYPE` / `AWWW_TRANSITION_FPS` / `AWWW_TRANSITION_DURATION` / `AWWW_TRANSITION_STEP` / `AWWW_TRANSITION_BEZIER`。
- awww ソケット ready を短時間ポーリング（`awww query`）してから `awww img "$1" --transition-type ... --transition-fps ... --transition-duration ... --transition-step ... --transition-bezier ...`。
- 設定センターは `hyprctl-state set AWWW_TRANSITION_DURATION 5` 等で `state.env` を書くだけ。次回転（`pypr wall next` 含む）で自動反映。即プレビューは `set.sh "$(cat last_wallpaper)"` を直接実行。

### 3. 変更: `scripts/wallpaper/apply.sh` → `scripts/wallpaper/post.sh`（pyprland `post_command`）

現 `apply.sh` から以下を除去:

- `awww img` 呼び出し（→ `set.sh` に移譲）。
- `WALLPAPER_BOOT` / `RANDOM_ON_STARTUP` 由来の分岐。
- notify（`maybe_notify` と `WALLPAPER_NOTIFY` 参照）。

残す/整理:

- matugen（`--source-color-index` は `MATUGEN_SOURCE_INDEX` / `MATUGEN_RANDOM_INDEX` から。fallback は index 0）。
- wallust（`@color0..15` 生成）。matugen と並列実行し全 wait。
- 波及: `waybar/reload-css.sh` / 全 ghostty へ `SIGUSR2` / `hyprctl reload`（border 色伝播）。
- `last_wallpaper` 記録（mode.sh が参照するため必須）。

### 4. 変更: `scripts/hyprctl-state` の DEFAULTS

- 削除: `WALLPAPER_NOTIFY` / `WALLPAPER_ROTATION` / `WALLPAPER_INTERVAL_SEC` / `WALLPAPER_RANDOM_ON_STARTUP`
- 残す: `MATUGEN_SOURCE_INDEX` / `MATUGEN_RANDOM_INDEX`
- 追加: `AWWW_TRANSITION_TYPE=grow` / `AWWW_TRANSITION_FPS=120` / `AWWW_TRANSITION_DURATION=3` / `AWWW_TRANSITION_STEP=90` / `AWWW_TRANSITION_BEZIER=.23,1,.32,1`

### 5. 変更: `lua/keybinds.lua`

```lua
-- 壁紙（pyprland wallpapers）
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("pypr wall next"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("pypr wall pause"))
```

`SUPER + W` は現状未使用。

### 6. 削除

- `scripts/wallpaper/init.sh`
- `scripts/wallpaper/pick.sh`
- `scripts/wallpaper/rotate.sh`
- `scripts/wallpaper/thumb.sh`
- `lua/autostart.lua`（内容は壁紙 exec のみ → ファイルごと削除）
  - あわせて `lua/hyprland.lua` の `require("autostart")` を削除。
  - あわせて `hyprland/default.nix` の `xdg.configFile."hypr/autostart.lua"` を削除。
- `hyprland/default.nix` の `home.sessionVariables.WALLPAPER_DIR`（参照元が全て消えるため）。
  - これにより `hyprland/default.nix` の関数引数 `dotfilesDir` が未使用になる → 引数からも除去（deadnix 対策）。

## 既知のエッジ / リスク

1. **mode.sh 連携**: ベッド/デスクモード切替時、`mode.sh` は `last_wallpaper` を awww に再適用する。`post.sh` が `last_wallpaper` を書き続けるので mode.sh は動作継続。ただしモード切替に伴うモニタ再構成で pyprland が別のランダム壁紙へ差し替える可能性が残る（軽微・手動操作時のみ）。**完全な解消は将来の pyprland monitors プラグイン導入時**（別タスク）。
2. **pause は揮発**: `_paused` は pyprland のメモリ内状態。pyprland 再起動で回転 ON（デフォルト）に戻る。
3. **awww ソケット ready レース**: systemd の `After`/`Requires` はプロセス起動順のみ保証。初回 `set.sh` の `awww img` がソケット未 ready で失敗しないよう `set.sh` に短い `awww query` 待ちを入れる。
4. **interval は宣言的**: 実行時変更不可。変更は Nix 編集 + `nix run .#switch`。
5. **`~/.config/scripts/notify.sh` 不在エラー**（todo 既知項目）は notify 全廃により解消（副次的）。

## 検証手順

1. `nix run .#build` でビルド通過。
2. `nix run .#fmt -- --fail-on-change`（deadnix: `WALLPAPER_DIR` / `dotfilesDir` の取り残しが無いこと）。
3. `nix run .#switch` 後:
   - `systemctl --user status awww-daemon pyprland` が active。
   - 起動時に壁紙が表示される。
   - `SUPER + W`（次へ）/ `SUPER + SHIFT + W`（停止）が動作。
   - interval 経過 or `pypr wall next` で壁紙切替時に色連動（waybar / ghostty / border）が追従。
   - `hyprctl-state set AWWW_TRANSITION_DURATION 5` 後 `set.sh "$(cat ~/.local/state/hypr/last_wallpaper)"` で新 transition が反映。
   - `journalctl --user -u pyprland -f` にエラーが出ない。

## ロールアウト後の残タスク（本設計スコープ外）

- todo.md「pyprland の導入」から wallpapers の項目を消化済みにする。
- 設定センター（quickshell）からの transition / 壁紙操作 UI 実装。
- monitors プラグイン導入時に mode.sh を置換（エッジ 1 の恒久解消）。
