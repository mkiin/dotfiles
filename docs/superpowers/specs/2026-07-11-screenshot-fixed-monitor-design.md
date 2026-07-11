# screenshot.sh に「特定モニター固定・全画面スクショ」を追加

## 目的

`screenshot.sh` の `output` モードは現状フォーカス中のモニターを撮る。
フォーカス位置に依存せず、**特定のモニター（DP-3）をかならず全画面で撮る**
キーバインド 1 発の手段が欲しい。

## 対象ファイル

- `home-manager/desktop/hyprland/scripts/screenshot.sh`
- `home-manager/desktop/hyprland/lua/keybinds.lua`

## アプローチ

新モードを増やさず、既存 `output` モードにオプション引数でモニター名を
受け取れるよう拡張する（`output = 画面まるごと` の責務を保つ）。

- `screenshot.sh output` … 現行どおりフォーカス中モニターを撮る（後方互換）
- `screenshot.sh output DP-3` … 引数のモニターを固定撮影

モニター名リテラル（DP-3）はスクリプトにハードコードせず **keybind 側に持たせる**。
将来別画面が欲しくなっても keybind を足すだけで済む。

## 仕様

### `screenshot.sh` の `output` ケース

第2引数 `$2` を任意のターゲットモニター名として扱う。

- 引数あり: `hyprctl monitors -j` に該当 `name` が存在するか確認
  - 存在する → `monitor` にセットして通常の全画面撮影へ
  - 存在しない → `notify-send` で「モニター <name> が見つかりません」を出し、
    **何も撮らず `exit 0`**（誤った画面を撮らない安全側）
- 引数なし: 現行どおり `.focused` のモニターを使う

保存先は既存構造 `output/<モニター名>/` を踏襲。DP-3 固定分は `output/DP-3/` に溜まる。
以降の `grim -o "$monitor"` 以下は変更なしで流用。

実装イメージ:

```bash
output)
  target="${2:-}"
  if [ -n "$target" ]; then
    exists=$(hyprctl monitors -j | jq -r --arg n "$target" 'any(.[]; .name == $n)')
    if [ "$exists" != "true" ]; then
      notify-send -a "screenshot" "スクリーンショット" "モニター ${target} が見つかりません"
      exit 0
    fi
    monitor="$target"
  else
    monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name // "unknown"')
  fi
  out_dir="${base_dir}/output/${monitor}"
  ;;
```

### keybind 追加（`lua/keybinds.lua`）

現状:

- `mainMod + P` … region
- `mainMod + SHIFT + P` … window
- `mainMod + CTRL + P` … output（フォーカス中）

追加:

- `mainMod + ALT + P` … `screenshot.sh output DP-3`

## 不在時の挙動

DP-3 が存在しない（bed プロファイル / 未接続）→ 通知を出して何も撮らずに終了。
フォールバックで別画面を撮ることはしない。

## 反映

home-manager 経由。`nix run .#build` で通してから `nix run .#switch`。
スクリプト・keybind とも生成ファイルなので手動配置は不要。

## 非対象（YAGNI）

- 実行時のモニター選択 UI（slurp 等）は作らない
- 複数モニター一括撮影は対象外
- モニター名の設定化（Nix 変数）はしない。keybind リテラルで足りる
