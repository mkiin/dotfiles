# Waybar スタイリングの落とし穴と reset パターン

GTK4 + waybar (layer-shell) の組合せで踏みやすい見た目バグと、entry style.css に入れておく汎用 reset。

anom / noro どちらの style プリセットでも同じ症状が出るので、どのテーマを採用しても entry 側でこれらの reset を当てておくのが安全。

---

## 症状と原因

GTK4 のデフォルトテーマ Adwaita は、**通常のアプリケーション** で使われることを想定して `button` 要素にアプリ的な装飾を盛る。これが waybar (= layer-shell 上の小さなステータスバー) には過剰で、custom CSS を上書きしてしまう。

| 見た目の症状 | 原因 |
|---|---|
| **ホバー時にボタンの周りに白い輪郭リングが出る** | Adwaita の `button:hover` が `box-shadow` で focus ring を描画 |
| **ホバー時にボタン背景が白くなる (custom CSS の色を上書き)** | Adwaita の `button:hover` に `background-image: linear-gradient(...)` で白いグラデが重なる |
| **文字に影が乗って読みにくい** | Adwaita の `button` に `text-shadow` |
| **キーボード focus 時に角張った輪郭が出る** | Adwaita の `:focus-visible` の `outline` |
| **ホバー/状態切替時に pill 形 (border-radius) の clip box が一瞬ズレ、背景がはみ出す** | GTK4 widget の既定 `min-height` が re-measure を起こす (※多くの custom style はこれを `* { min-height: 0; }` でリセットしてる、足りない style もある) |

---

## reset パターン

`~/.config/waybar/style.css` (entry) の **`@import` の後** に追加:

```css
/* GTK4 Adwaita 既定の button :hover/:focus-visible で発生する装飾を全部無効化。 */
button {
    box-shadow: none;
    outline: none;
    text-shadow: none;
    background-image: none;
}

button:hover,
button:focus,
button:focus-visible {
    box-shadow: none;
    outline: none;
    background-image: none;
}
```

`@import` の **後** に置く事が重要 (cascade で custom style の `button` 規則を上書きしない方向で、Adwaita 既定だけ消すために最後勝ち)。

`* { min-height: 0; }` も同じ場所に置けるが、custom style 側で既に当ててる事が多いので **症状が出てから足す方が無難**。

---

## どの style に reset が要るか

**reset 不要 (style 自体に対策済み):**
aurora-ribbon, cyber-duo, floating-glass-pills, glass-modern, modern-glass, modern-tabs, neon-glow-islands, soft-gradient, zen, anom Material Pills

**reset 必須 (`background-image: none` 等のリセットが style 側に無い):**
noro original, capsule, capsule-nobg, island, island-squared, background-bordered, background-no-border, back-alllnoth-*, back-noth-nbor, styles3

ただし entry 側で **常に reset を入れておく方針** だと、style 切替時にバグが再発しないので推奨。

---

## なぜ Adwaita が問題になるか

waybar はそれ自体が GTK4 アプリで、ユーザーがテーマを設定していない場合 (= `~/.config/gtk-4.0/settings.ini` に `gtk-theme-name` 未指定) は GTK4 デフォルトの Adwaita が当たる。

Adwaita は通常の **GUI アプリのボタン** (decoration headers, dialog buttons 等) を想定しており、focus indicator や hover gradient はそこでは UX 上必要。だが waybar の各モジュールは **クリックすると即座に動作 (例: pulseaudio click → pavucontrol 起動)** で、focus 状態を持続させる UX ではない。よって focus indicator は不要で、見た目を阻害する。

GTK theme を別物 (Materia, Catppuccin GTK 等) に変えれば Adwaita 既定は消えるが、waybar だけで完結したかったら CSS reset が現実解。

---

## 関連ファイル

- 本 reset の実装: `home/dot_config/waybar/style.css` 末尾
- noro variant 用の同 reset: `home/dot_config/waybar/noro/style.css` 末尾
- anom variant の独自 reset: `home/dot_config/waybar/anom/style.css` の `*` 規則 (`min-height: 0` 含む)
