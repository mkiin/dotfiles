# SDDM ログイン画面レイアウトの設計

sddm-astronaut-theme を conf 調整だけでカスタムし、壁紙と配色を dotfiles から注入するログイン画面を作る。
QML には手を入れず、nixpkgs の `sddm-astronaut` パッケージを土台にする。

## 要件

- **スコープ**：conf 調整のみ。QML の fork はしない。
- **壁紙**：`images/login/login.png` をビルド時にテーマへ焼き込む。デスクトップ壁紙との連動はしない。
- **フォーム**：画面中央に配置する。ブラーもフォーム背景も使わず透明にする。
- **配色**：ビルド時に matugen で login.png から生成する。壁紙を差し替えれば配色も追従する。
- **日付表示**：英語ロケールで「曜日, 月 日」（例 `Wednesday, July 16`）。
- **表示部品**：電源ボタンとセッション選択は表示する。仮想キーボードは非表示にする。

## データフロー

```
images/login/login.png ──┬─(ビルド時)─> matugen ──> Themes/custom.conf
                         └────────────コピー────> Backgrounds/login.png
home-manager/desktop/matugen/templates/sddm-theme.conf ─┘
```

**sddm-theme.conf** は astronaut の conf 全体のテンプレートである。
レイアウトや日付フォーマットなどは完成値で直書きし、色だけを `{{colors.primary.default.hex}}` 形式の matugen プレースホルダで書く。
既存の runtime テンプレート群（waybar 等）と同じ `home-manager/desktop/matugen/templates/` に置くが、レンダリングのタイミングが異なる。
runtime テンプレートはデスクトップ壁紙の変更時に `~/.config` へ描き出されるのに対し、sddm-theme.conf は nix build 中に一度だけレンダリングされる。
そのためデスクトップ側の `config.toml` には登録しない。

matugen の呼び出しは、derivation 内で生成する sddm 1 エントリだけの config.toml で行う。
モードとスキームはデスクトップ側と同じ値（dark、デフォルトスキーム）を指定し、画像から色への変換ロジックを waybar 等と揃える。

## ファイル配置

リポジトリに追加・変更するのは次の 2 箇所だけである。

- `home-manager/desktop/matugen/templates/sddm-theme.conf`（新規）：conf 全体のテンプレート。
- `nixos/desktop/sddm/default.nix`（変更）：テーマ derivation の差し替え。weston・カーソル・フォントの既存設定は維持する。

ビルド成果物では、テーマディレクトリ内に `Backgrounds/login.png` と `Themes/custom.conf` が生成され、`metadata.desktop` の `ConfigFile` が custom.conf を指す。
upstream のプリセットと壁紙は削除しない。
消す加工を足すより残す方が derivation が単純であり、未使用ファイルに実害はない。

## パッケージ定義

`pkgs.sddm-astronaut.overrideAttrs` で `postInstall` を追加する。

```nix
theme = pkgs.sddm-astronaut.overrideAttrs (old: {
  nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.matugen ];
  postInstall = ''
    # 1. login.png を Backgrounds/ へコピー
    # 2. ビルド用 config.toml を生成し matugen image でテンプレートを Themes/custom.conf へレンダリング
    # 3. metadata.desktop の ConfigFile を Themes/custom.conf へ sed
  '';
});
```

自前 mkDerivation ではなく overrideAttrs を選ぶのは、フォントインストールや Qt モジュールの propagate、Renovate 経由の nixpkgs 更新追従を upstream 定義のまま残すためである。
`embeddedTheme` / `themeConfig` の override 機構は使わない（custom.conf が唯一の設定になるため）。

テンプレートと壁紙は `"${inputs.self}/..."` で参照する。
`dotfilesDir` / `lnk` は実行時 symlink 用であり、sandbox 内のビルド入力には使えない。

## テンプレートの主要キー

| キー                                              | 値                        |
| ------------------------------------------------- | ------------------------- |
| `Background`                                      | `"Backgrounds/login.png"` |
| `FormPosition`                                    | `"center"`                |
| `PartialBlur` / `FullBlur` / `HaveFormBackground` | すべて `"false"`          |
| `Locale`                                          | `"en_US"`                 |
| `DateFormat`                                      | `"dddd, MMMM d"`          |
| `HourFormat`                                      | `"HH:mm"`                 |
| `ScreenWidth` / `ScreenHeight`                    | 2560 / 1440               |
| 仮想キーボード関連                                | 非表示                    |
| 電源ボタン・セッション選択                        | 表示                      |
| `Font`                                            | Open Sans（テーマ同梱）   |

色キーの役割マッピングは次を基本とする。

- **見出し・時計**：on_surface 系。
- **アクセント**（ハイライト、ホバー、ログインボタン）：primary 系。
- **入力欄**：surface / on_surface 系。

文字の可読性が壁紙次第になるため、`DimBackground` を 0.2 前後で入れておき、実機確認で調整する（透明方針は維持し、不要なら 0 にする）。

## エラーの扱い

matugen の失敗やプレースホルダの誤記はビルドエラーとして検出される。
silent fallback は設けない。

## 検証

1. `nix run .#build` と treefmt を通す。
2. ビルド成果物の `Themes/custom.conf` に色が実値で埋まっていること、`metadata.desktop` が custom.conf を指すことを grep で確認する。
3. `sddm-greeter-qt6 --test-mode --theme <storeパス>` でレイアウトを目視する（ログアウト不要）。
4. switch して実機のログイン画面で確認する。
