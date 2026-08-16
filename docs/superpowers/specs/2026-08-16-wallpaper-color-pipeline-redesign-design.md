# 壁紙適用と色生成パイプラインの再設計

日付: 2026-08-16
状態: 設計承認済み

## 背景と問題

セッション起動時に、rofi のサムネイル背景・matugen のカラートークン・実際の壁紙表示が別々の画像に由来する不整合が発生していた。

調査で確定した事実:

- awww-daemon は output 出現時に `~/.cache/awww/<output>` から前セッションの壁紙を自動復元する。
- `set.sh` の ready 待ちは「`awww query` が応答するか」しか見ておらず、output 0 個でも通過する。実際に `FALLBACK` キャッシュへの書き込みが残っており、output 未登録状態で `awww img` が実行された証拠となった。
- pyprland は起動直後に必ず 1 枚適用するため、毎回このレース窓に入る。
- 結果、pyprland が投げた画像（色・last_wallpaper に反映）を、後から現れた output へのキャッシュ復元（前セッションの画像）が上書きし、表示だけが古い画像になった。
- 加えて `post.sh` は適用結果を検証せず、`reload-css.sh` は nix store の read-only symlink である `style.css` を書き直そうとして毎回失敗していた。

根本の構造欠陥は、壁紙の書き込み経路が 3 本あることだった:

1. pyprland → `set.sh`（表示）+ `post.sh`（色）。表示と色が別プロセスで、間に何の保証もない。
2. `mode.sh` → `awww img` 直叩き。色パイプラインを通らない。
3. awww-daemon のキャッシュ復元。誰の管理も通らない隠れた書き手。

## 設計原則

**書き込み経路は `apply.sh` の 1 本に限定する。正しさは呼び出しタイミングやイベント配送ではなく、`apply.sh` 内部の実状態照合（`awww query`）が担う。**

- イベント駆動の常駐リスナーは採用しない。呼び出し元は自分が呼ぶべきタイミングを知っている（pyprland のローテーション、mode.sh の configreloaded 後）ので、決定的な同期呼び出しで足りる。
- 呼び出し元の事情で挙動を変えるフラグ（`--no-transition` 等）は持たない。分岐が必要かどうかは apply.sh が実状態との比較で内部判断する。

## アーキテクチャ

```
呼び出し元（すべて同期呼び出し）
  ├─ pyprland: command = apply.sh [file]      （post_command は廃止）
  ├─ mode.sh:  apply.sh "$(<last_wallpaper)"  （configreloaded 待ちの後）
  └─ 手動:     apply.sh <image>

apply.sh <image>
  0. flock で直列化
  1. output 揃い待ち: awww query の行数 == hyprctl monitors の数（上限 5 秒）
  2. 表示照合:   全 output が既に <image> を表示中なら 3-4 をスキップ
  3. awww img <image>（state.env のトランジション設定を使用）
  4. 表示検証:   awww query == <image> を確認。不一致なら 1 回だけ押し直し、
                なお不一致なら MISMATCH をログして色生成へは進まず終了
  5. 色メモ化照合: 前回色生成した画像と同じなら 6-7 をスキップ
  6. matugen / wallust 並列実行（失敗時 --source-color-index 0 フォールバック維持）
  7. 波及: waybar CSS 書き直し / ghostty SIGUSR2 / hyprctl reload
  8. last_wallpaper 書き込み（表示成功の記録として最後に書く。色の成否は last_colored が持つ）

awww-daemon: --no-cache で起動（キャッシュ復元という隠れた書き手を排除）
```

### 表示照合（工程 2）と表示検証（工程 4）の役割

どちらも「自分の記録やコマンドの成否ではなく実状態だけを信じる」原則の適用だが、位置と目的が異なる。

- **表示照合**（入口ガード）: そもそも作業が必要かを実状態に聞く。同一画像の再適用（mode.sh 経由など）での無駄撃ちと再描画アニメーションを抑止し、冪等性を与える。
- **表示検証**（出口ゲート）: 命じた作業が反映されたかを実状態に聞く。`awww img` の正常終了は IPC 受理しか意味しない（今回の障害の核心）ため、適用後に実表示を読み直してから色生成へ進む。

比較は `awww query` の表示状態全体で行う。画像未適用の output は `image:` 行ではなく `color: 000000` 行として現れるため、`image:` 行だけを抽出すると黒モニタが照合から消え、「全 output が表示済み」と誤判定する。照合・検証とも image/color を含む状態行を比較し、**color 状態は不一致として扱う**（モード切替で新規有効化された黒モニタへの適用はこの規則で保証される）。

### 色メモ化（工程 5）

apply.sh が「前回色生成に使った画像パス」を `$XDG_STATE_HOME/hypr/last_colored` に記録し、同一なら matugen / wallust / 波及をスキップする。
呼び出し元が渡すフラグではなく内部の比較判断であり、mode.sh 経由の同一画像再適用やイベント連発時の無駄撃ちをここで吸収する。

## mode.sh の変更

mode.sh の責務はモニタ構成切替（monitors.lua 書き換え、hyprctl reload、configreloaded 待ち、waybar 再起動、WS 復元）に純化する。

- 削除: awww の output ポーリング、`awww img --transition-type none` 直叩き、`awww restore` フォールバック（約 15 行）。output 待ちは apply.sh 工程 1 に吸収される。
- 追加: configreloaded 待ちの直後に `apply.sh "$(<last_wallpaper)"` を 1 行呼ぶ。last_wallpaper が無い/読めない場合はスキップ（pyprland の起動時適用が正を作る）。

旧 `--transition-type none` の特例は不要になる。`--no-cache` 後の世界では新しく有効化されたモニタは黒から始まり、黒 → 壁紙のトランジションはログイン時と同じ見え方なので、「切替時だけ即時」という特例の根拠が消える。

### モード切替シーケンス（desk → bed）

1. アクティブ WS を退避
2. monitors.lua を書き換え
3. socket2 購読 → hyprctl reload → configreloaded 待ち
4. `apply.sh "$(<last_wallpaper)"`
   - 新規有効化モニタは黒（`color:` 状態）なので照合が不一致となり、awww img 実行
   - 画像は同一なので色メモ化により色生成と波及はスキップ
5. waybar kill → 再起動（layer surface 非追従バグ対策、現行どおり）
6. WS 復帰

pyprland のローテーションと衝突した場合は flock で直列化され、後勝ちで収束する。
このとき mode.sh は相手の適用（トランジション＋色生成で数秒）を待ってから自分の処理を行うため、切替完了がその分遅れる。設計どおりの直列化の代償として許容する。

## 周辺の修正

### rofi の情報源一本化

`rofi/launch.sh` のサムネイル背景の情報源を `last_wallpaper` ファイルから `awww query` の実表示に変更する。
表示とサムネイルが構造的にずれなくなる。パースは `currently displaying: image:` 行から画像パスを取り、複数 output は先頭を使う。

### waybar の色反映の修復

現在 `reload-css.sh` は nix store への read-only symlink である `~/.config/waybar/style.css` を O_TRUNC で書き直そうとして毎回失敗している。
`style.css` の配布を symlink から書き込み可能な実ファイルコピー（home.activation で switch のたびに上書き）に変え、書き直しトリックを復活させる。
`style.nix` が寸法・質感の単一情報源である点は変わらない。

## 廃止するもの

- `set.sh` / `post.sh`（apply.sh に統合）
- pyprland の `post_command`
- mode.sh の壁紙ブロック
- awww のキャッシュ復元（`--no-cache`）

## エラー処理

- output 揃い待ちタイムアウト（5 秒）: ログを残し、**入口の表示照合を無効化して無条件に awww img を打つ**。awww に未登録の output は `query` に行が出ず照合では検出できないため、「次の照合で収束する」は成り立たない。無条件適用なら、遅れて登録された output には間に合う（タイムアウト後も現れない output は救えず、次の呼び出しが収束点になる）。
- 表示検証の不一致: 1 回だけ押し直し。なお不一致なら MISMATCH をログし、古い画像から色を作らないよう色生成へは進まない。無限リトライはしない（次の契機で収束）。
- 表示検証の限界: awww-daemon は `img` 受理時に表示情報を同期更新してから応答するため検証に待ちは不要だが、受理後の描画が画像寸法チェック等で破棄されても `query` は新パスを返し続ける。解像度変化と重なった場合など、検証が偽陽性になる窓が残る（その場合は表示だけ古く色は新しく、次の適用で直る）。
- matugen 失敗: `--source-color-index 0` での再試行を維持。失敗時は `last_colored` を更新せず、次の呼び出しが色生成を再試行する。
- リスナー等の常駐部品は追加しないため、最悪でも pyprland の次のローテーション（30 分間隔）が収束点になる。
- ログは現行の `wallpaper-apply.log` を継続。

## 起動時の挙動（仕様）

ログイン時の壁紙は pyprland がランダムに選ぶ 1 枚を正とする。
前セッションの壁紙は継続しない（awww キャッシュ復元の廃止はこの仕様決定に基づく）。

## 検証方法

1. `nix run .#build` 通過後 switch し再ログイン → `awww query`・`last_wallpaper`・`colors.rasi` の由来画像が三点一致する
2. `pypr wall next` → 三点が新画像に揃う
3. モード切替（SUPER+SHIFT+D/B）→ 壁紙が割れず、色が変わらない
4. rofi 起動 → サムネイルが実表示と一致する
5. 色変更後に waybar へ反映される（log に reload-css failed が出ない）
6. `wallpaper-apply.log` に MISMATCH が出ていない

## スコープ外

- モニタホットプラグへの自動追従（イベントリスナー）。必要になったら apply.sh を呼ぶだけの薄いリスナーとして追加できる設計になっている。
- ghostty への色反映方式の変更（現行の SIGUSR2 を維持）。
