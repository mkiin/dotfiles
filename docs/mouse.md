# Mouse Configuration

G703 (Lightspeed ゲーミングマウス) と M575SP (Bolt トラックボール) の宣言的設定。

## アーキテクチャ

```
G703 (Lightspeed)              M575SP (Bolt)
      │                              │
      │ hidraw                       │ hidraw
      ▼                              ▼
libratbag (ratbagd, root)      Solaar (user)
      │                              │
      │ DBus                         │ HID++ + config.yaml
      ▼                              ▼
オンボードメモリへ書込             ~/.config/solaar/config.yaml
```

ハードウェア層で「素のサイドボタンコード (BTN_SIDE / BTN_EXTRA / KEY_F24)」を OS に渡すよう揃えている。

## コンポーネント一覧

| 役割 | ファイル / コマンド |
|---|---|
| G703 設定 (DPI / ボタン / Report Rate) | `home/dot_config/mouse/executable_g703h.sh` → `ratbagctl` |
| M575 設定 (DPI) | `home/dot_config/mouse/executable_m575sp.sh` → `solaar config` |
| G703 用デーモン | `ratbagd.service` (systemd) |

## G703 (`g703h.sh`)

`ratbagctl` で **オンボードメモリ** に書き込む。電源を抜いても別 OS をブートしても保持される (Windows の G HUB が触れば上書きされるので、戻したい時はこのスクリプトを再実行)。

| 項目 | 値 |
|---|---|
| アクティブプロファイル | Profile 0 (1-4 は disabled) |
| Report Rate | 1000Hz |
| DPI | 1600 (単一) |
| Button 3 (左サイド) | `button 4` = BTN_SIDE |
| Button 4 (右サイド) | `button 5` = BTN_EXTRA |
| Button 5 (天面 DPI) | `key KEY_F24` |
| LED 0/1 | off |

libratbag のエイリアス名 (`yelling-zokor` 形式) は host ごとに乱数生成される。スクリプトでは `ratbagctl list` の先頭行から動的取得しているため、別マシンでもそのまま動く。

**変更フロー**: `g703h.sh` を編集 → `chezmoi apply` → `~/.config/mouse/g703h.sh` を実行 (DRY_RUN=1 で叩く `ratbagctl` だけ確認可能)。

## M575SP (`m575sp.sh`)

`solaar config` で **ホスト側 `~/.config/solaar/config.yaml`** に書き込む。デバイス本体には保存されない (M575 はオンボードプロファイルを持たない)。

| 項目 | 値 |
|---|---|
| DPI | 800 |
| その他 | デフォルト維持 |

設定キーの全リストは `solaar config "ERGO M575SP"` (値を省略) で確認可能。利用可能なのは `dpi` / `lowres-scroll-mode` / `reprogrammable-keys` / `divert-keys` / `change-host` の 5 項目のみ。

**Solaar GUI を触らない**: GUI でも設定変更できるが、`config.yaml` を書き換えるため `m575sp.sh` と drift する。確定値の変更は **必ずスクリプト経由**。

## 新マシンセットアップ手順

```bash
# G703 用 DBus デーモン
sudo systemctl enable --now ratbagd

# dotfiles を apply
chezmoi diff
chezmoi apply

# マウス設定をデバイス/host に書込
~/.config/mouse/g703h.sh    # G703 オンボードメモリへ
~/.config/mouse/m575sp.sh   # M575SP solaar config へ
```

`solaar` の autostart は任意 (M575 の設定はホスト側 config.yaml に永続化されるので、solaar 常駐がなくても次回ブート時に Logitech driver が config.yaml を読んで適用)。

## 既知の制限

| 項目 | 内容 | 対処 |
|---|---|---|
| Windows G HUB がオンボード上書き | dual-boot で Windows 側 G HUB が触ると G703 のオンボード設定が壊れる | Linux に戻ったら `~/.config/mouse/g703h.sh` を再実行 |
| G703 active profile の漂流 | スリープ復帰や ratbagd 再起動後、disabled な Profile 1 が "active" 扱いに戻り実効 DPI が変わる | `g703h.sh` で Profile 1-4 にも同じ DPI を書込んでフォールバック先を統一済 |
| Solaar GUI による drift | GUI で設定変更すると `config.yaml` が m575sp.sh と乖離 | GUI は探索目的のみ、確定値は必ずスクリプトへ転記 |
| Solaar が出す Wayland/uinput 警告 | `rules cannot access modifier keys in Wayland` 等 | Solaar Rules 機能を使わない方針なので無視 OK |

## 参考リンク

- libratbag: https://github.com/libratbag/libratbag
- Piper (GUI): https://github.com/libratbag/piper
- Solaar: https://github.com/pwr-Solaar/Solaar
