# SDDM の配色モードを壁紙の輝度で決める

ログイン壁紙の平均輝度から matugen の `--mode` を選び、明るい壁紙には light、暗い壁紙には dark のパレットを生成する。
判定はテーマ derivation のビルド時に一度だけ行う。

この機能は一度 `065d252` で実装し、`e48d1a6` で削除した経緯がある。
本設計は同じ機能の作り直しであり、削除に至った不安定さの原因を取り除くことを主眼に置く。

## 要件

- **判定対象**：`images/wallpaper/selection.json` の `login` が指す壁紙。
- **判定時点**：テーマ derivation の `postInstall`。実行時ではなくビルド時に一度だけ決める。
- **判定結果**：matugen の `--mode` に渡す `light` または `dark`。
- **スキーム**：`--type` は指定しない。既定の `scheme-tonal-spot` のままにする。
- **手動上書き**：用意しない。判定を外す壁紙が現れた時点で改めて検討する。

## 判定規則

平均輝度を求め、0.40 を境に light と dark を分ける。

```bash
luma=$(magick "${wallpaper}" -alpha off -colorspace gray -format '%[fx:mean]' info:)
mode=$(awk -v l="$luma" 'BEGIN { print (l > 0.40) ? "light" : "dark" }')
```

`-alpha off` を省略できない。
`%[fx:mean]` は全チャンネルの平均を返すため、アルファチャンネルを持つ画像では常に 1.0 のアルファが平均に混ざる。
実測では gintoki の輝度が 0.1903 から 0.5952 へ変わり、これは `(0.1903 + 1.0) / 2` に一致した。
リポジトリの壁紙 10 枚のうち 4 枚がアルファ付き PNG であり、この混入は判定を静かに反転させる。

## 閾値を 0.40 にする根拠

手持ちの壁紙 10 枚の平均輝度は、二つの塊に分かれて分布する。

| 壁紙     | 輝度   | mode  |
| -------- | ------ | ----- |
| rennala  | 0.1640 | dark  |
| gintoki  | 0.1903 | dark  |
| lucy     | 0.2622 | dark  |
| miquella | 0.2985 | dark  |
| raiden   | 0.3147 | dark  |
| yukino   | 0.4965 | light |
| tsubasa  | 0.5081 | light |
| mitsuki  | 0.5397 | light |
| kafka    | 0.6248 | light |
| frieren  | 0.7517 | light |

暗い側は 0.16 から 0.31、明るい側は 0.50 から 0.75 に収まり、その間には 0.18 幅の空白がある。
空白の中央にあたる 0.40 を閾値に置くと、10 枚すべてが 0.085 以上のマージンを持つ。

削除前の実装は閾値に 0.5 を使っていた。
0.5 は空白ではなく明るい塊の縁に位置するため、yukino と tsubasa が閾値から 0.01 以内に並ぶ。
とりわけ yukino は、平均の取り方を `-resize 1x1!` にするか全画素平均にするかで 0.5072 と 0.4965 に振れ、0.5 をまたいで light と dark の両方に倒れた。
現行のログイン壁紙が実装の細部で反転する状態であり、これが削除の原因だと考えられる。
閾値を 0.40 に移すと、この 0.01 程度の振れは結果を変えなくなる。

## スキームを自動選択しない理由

`--type` は 9 種類の値を取るが、壁紙のトーンから導く根拠がない。

第一に、彩度は 0.24 から 0.57 の連続分布であり、輝度のような自然な切れ目がない。
閾値を置いても位置に根拠がなく、0.5 で失敗したのと同じ構図になる。

第二に、type は地の色を変えない。
yukino を light モードで 9 種類すべて試すと、`surface` は `#f9f9f9` から `#fdf7ff` の範囲に収まり、`on_surface` もほぼ動かない。
変わるのは `primary` と `tertiary` だけであり、`scheme-monochrome` の `#000000` から `scheme-vibrant` の `#293fff` まで幅がある。
本テーマでは時計に `primary`、日付に `tertiary` を割り当てているため、type の選択は時計と日付の色の選択に等しい。
これは壁紙のトーンから決まる問題ではなく、好みの問題である。

## データフロー

```
images/wallpaper/selection.json ──> login の壁紙
                                      ├─(magick)─> 平均輝度 ─(awk)─> mode
                                      └────────コピー───────> Backgrounds/login.png
                                                                 │
home-manager/desktop/matugen/templates/sddm-theme.conf ──> matugen --mode "$mode"
                                                                 └──> Themes/custom.conf
```

## ファイル配置

変更するのは `nixos/desktop/sddm/default.nix` の 1 箇所だけである。
テーマ derivation の `nativeBuildInputs` に `imagemagick` を戻し、matugen を呼ぶ直前に輝度の測定と mode の決定を挟む。
matugen テンプレートと weston やカーソルの既存設定は変更しない。

## 検証

ビルドした `custom.conf` を読み、yukino が light 側の値になることを確認する。
`surface` が `#fbf8ff` 系、`primary` が `#545a92` になれば light モードで生成されている。

あわせて壁紙 10 枚の輝度を測り、mode の判定結果が上表と一致することを確認する。
見た目は `nixos/desktop/sddm/theme-preview.sh` で確認できる。

## 既知の影響

現行のログイン画面の見た目が変わる。
yukino は light に倒れるため、暗いフォームに `#bdc2ff` の時計という現在の配色は、白いフォームに `#545a92` の時計に置き換わる。
