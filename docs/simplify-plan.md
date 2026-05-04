# Shell スクリプト simplify プラン

dotfiles 配下の shell スクリプト群 (約 25 本) の simplify 計画。
**ロジック改造を主、コードスメル修正を副**として整理する。

定数抽出だけのリファクタは含めない (それは本リファクタの副産物として必要なら都度実施)。

---

## 構成

```
[本プランの三層]

  Layer 1  ロジック改造        ← 主目的。動作モデル / 状態設計の見直し
  Layer 2  構造再編            ← Layer 1 の必然として責務境界を引き直す
  Layer 3  記法スメル修正       ← Layer 1/2 の作業中に拾う or 単独修正
```

---

## Layer 1: ロジック改造

### L1: 壁紙ローテーション状態モデルを単一表現に統一 ★最重要

```
BEFORE                                       AFTER (案 A: queue モデル)
──────────────────────────────              ──────────────────────────────
state.env: PLAYLIST_INDEX=N                 state.env から PLAYLIST_INDEX 削除
cache    : [img1, img2, img3, ...]          cache: 残り queue
                                                   pick = head 取り出して書き戻す
pick.sh  :                                  
  IDX = state_get PLAYLIST_INDEX            pick.sh:
  PICK = cache[IDX]                           head=$(head -1 $cache)
  state_set PLAYLIST_INDEX (IDX+1)            tail -n +2 $cache > tmp && mv tmp $cache
  if IDX >= len: regenerate                   PICK=$head
                                              [[ ! -s $cache ]] && regenerate
"進捗" を index と cache の積で表現
→ cache 削除/手編集で容易に壊れる            "進捗" = queue の残量だけ
→ "round 完了" 判定が間接的                  → state.env シンプルに、cache が単一情報源
                                            → "round 完了" = "queue empty" で直接

                                              AFTER (案 B: cache 廃止)
                                            ──────────────────────────────
                                            shuffle cache 自体を捨てる。
                                            毎回 fd → shuf -n 1 で1枚選ぶ。
                                            
                                            "全枚回す" 要件があるなら A、
                                            "30分ごとにランダム1枚" だけなら B。
```

**判断ポイント**: 全枚をラウンドで消化したい? それとも毎回ランダムでいい?

---

### L2: rotate.sh の interval 反映を SIGUSR1 駆動に

```
BEFORE                                       AFTER
──────────────────────────────              ──────────────────────────────
rotate.sh:                                   rotate.sh:
  while :; do                                  trap 'reload_interval' USR1
    elapsed=0                                  reload_interval() {
    while :; do                                  INTERVAL=$(state_get ...)
      INTERVAL=$(state_get ...)                }
      (( elapsed >= INTERVAL )) && break       reload_interval
      sleep 30                                 while :; do
      elapsed=$((elapsed + 30))                  read -t $INTERVAL _ <unused
    done                                          # signal で USR1 が飛んでくると
    rotate                                        # read が中断 → 即 reload
  done                                           rotate
                                               done
30s ごとに state_get fork を打つ
INTERVAL=1800 で 30 分 = 60 fork              rofi-wallpaper-settings:
state 変更は最大 30s 遅延                      INTERVAL 変更後 pkill -USR1 -f rotate.sh

問題: poll 駆動の常駐コスト                   平常時 fork ゼロ。state 変更は即時反映。
     反映までの待ち時間
```

---

### L3: pick.sh の reroll を docs と一致させる

```
docs/scripts.md:61                          実装 (現状)
"~/.../last_wallpaper を読んで              shuffled list を index 順で消化
 直前と被らないよう reroll"                  ラウンド境界での被り対策なし
                                            (ラウンド内は shuffle で被らないが、
                                             cache 再生成直後の先頭画像が
                                             前ラウンド最後と一致する確率 1/N)

修正案:
  regenerate_cache() の最後で
    head=$(head -1 $cache)
    [[ "$head" == "$(<$LAST)" ]] && {
      sed -i '1{N;s/\(.*\)\n\(.*\)/\2\n\1/}' $cache  # 1行目と2行目を swap
    }
  画像が少ない (5枚以下) と体感する。docs と code を一致させる。
```

判断: 画像枚数が十分多ければ放置可能。今の wallpaper ディレクトリの枚数次第。

---

### L4: hyprctl reload を boot path で非同期化

```
BEFORE                                       AFTER
──────────────────────────────              ──────────────────────────────
apply.sh 末尾:                               apply.sh 末尾:
  hyprctl reload                              if [[ "${WALLPAPER_BOOT:-}" == 1 ]]; then
                                                hyprctl reload &
                                                disown
boot 経路 (init→pick→apply):                 else
  reload 完了まで apply プロセス残留           hyprctl reload  # rotation 経路は同期維持
  → 起動体感が伸びる                          fi
                                            
                                            init.sh: WALLPAPER_BOOT=1 exec PICKER

                                            boot 体感が数十〜数百 ms 短縮。
                                            border 色が一瞬遅れるだけ。
```

---

### L5: pkg-update の自前 cache を全廃

```
BEFORE                                       AFTER
──────────────────────────────              ──────────────────────────────
6本 + 各々が独立した cache_dir/TTL          2本に統合
                                            ┌──────────────────────────┐
aur-update.sh:                              │ pkg-check.sh             │
  TTL=1500                                  │   $1=name $2..=count_cmd │
  cache_file=...                            │   count=$($2 ... | wc -l)│
  if mtime < TTL: cat cache; exit           │   printf JSON            │
  count=$(yay -Qua | wc -l)                 └──────────────────────────┘
  printf JSON | tee cache                                ↑
                                            waybar config:
pacman-update.sh: 同型                        "exec": "pkg-check.sh aur yay -Qua"
mise-update.sh:   同型                        "interval": 1500
                                            
aur-upgrade.sh:                             ┌──────────────────────────┐
pacman-upgrade.sh : 同型                    │ pkg-upgrade.sh           │
mise-upgrade.sh:                            │   $1=signal $2..=cmd     │
                                            │   $2... && pkill -RTMIN+$1 waybar│
waybar interval は別途 1500s に設定済み      └──────────────────────────┘
                                            
cache_file/TTL/mtime 比較は全部不要         呼び出し情報は waybar config に集約
(waybar interval が同じ役割)                cache 廃止 → atomic write 問題も消滅
                                            新 PM 追加 = config に1行
```

---

### L6: mode.sh の awww 認識待ちを polling から event 駆動に

```
BEFORE                                       AFTER
──────────────────────────────              ──────────────────────────────
mode.sh:                                     Hyprland event socket を listen:
  for _ in {1..10}; do                         sock=$XDG_RUNTIME_DIR/hypr/$HIS/.socket2.sock
    (( $(awww query | wc -l) ==                exec 4< <(socat -U UNIX:$sock | grep -m1 monitor)
       expected )) && break                    # ↑ monitor event を 1 つ待つ
    sleep 0.1                                  exec 4<&-
  done

100ms × 10回 の固定 polling                   event-driven で確実に同期
雑、上限 1秒                                   実装コストはやや高い
                                              (Hyprland event 仕様調査要)
```

実装重め。優先度は中。

---

### L7: WALLPAPER_RANDOM_ON_STARTUP を state.env 経由に

```
BEFORE                                       AFTER
──────────────────────────────              ──────────────────────────────
init.sh:14                                   hyprctl-state DEFAULTS に追加:
  WALLPAPER_RANDOM_ON_STARTUP=true             [WALLPAPER_RANDOM_ON_STARTUP]=true
  ↑ ハードコード
                                            init.sh:
他の壁紙設定は全部 state.env 経由              WALLPAPER_RANDOM_ON_STARTUP=$(state_get ...)
だけここだけ抽象漏れ                          
                                            rofi-wallpaper-settings から toggle 可能になる。
```

---

## Layer 2: 構造再編

### S1: apply.sh を fan-out / notify / persist の3責務に分割

```
BEFORE  apply.sh (80行 1本)                  AFTER  apply.sh (~50行)
──────────────────────────────              ──────────────────────────────
- LOG/STATE 初期化                          - LOG/STATE 初期化
- awww img &                                - run_color_pipeline "$img"
- matugen &                                     ├ awww img &
- wallust &                                     ├ matugen &
- wait $awww_pid; rc=$?                         ├ wallust &
- wait $matugen_pid; rc=$?                      └ wait_all (pid配列ループ)
- wait $wallust_pid; rc=$?                  - notify_downstream
                                                ├ waybar reload-css
- waybar reload                                 ├ ghostty SIGUSR2
- ghostty SIGUSR2                               └ hyprctl reload (L4で非同期化)
- echo "$img" > $LAST                       - persist_last "$img"
- hyprctl reload                            - maybe_notify "$img"
- notify if $WALLPAPER_NOTIFY               
                                            並列タスク追加 = pid 配列に push するだけ
責務が水平にダラダラ並ぶ                     fan-out / notify / persist の境界が明確
3並列タスクが固定でハードコード              
```

L5 が wallpaper 改造、これは画像 apply 改造。独立して実施可。

---

### S2: pkg-update の構造再編 (L5 の必然)

L5 で記述済み。6本 → 2本ディスパッチャ + waybar config に呼出情報集約。

---

### rofi メニュー骨格について

```
rofi-{audio,bluetooth,network,settings,wallpaper-settings}.sh は
show_menu() の骨格 (items構築 / rofi 起動 / 戻り行検索 / Esc処理) が
5本に複製されている。

これは Layer 2 候補だが、ロジック改造ではなく重複排除 (= 単なる
共通関数化) なので **本プランからは除外**。
ユーザーが望めば追加するが、デフォルトでは扱わない。
```

---

## Layer 3: 記法スメル修正

### A1. `local var=$(cmd)` で exit code がマスクされる (SC2155)

```
ANTIPATTERN                                  FIX
──────────────────────────                  ──────────────────────────
local TODAY=$(jq ... <<<"$DATA")            local TODAY
                                            TODAY=$(jq ... <<<"$DATA")
                                            
set -e 配下でも local の終了コードが優先     失敗が伝播するようになる
され、jq 失敗が無視される

該当: weather.sh の数十箇所、init.sh / apply.sh の散在
```

### A2. `pkill -SIGUSR2 ghostty` が部分一致

```
ANTIPATTERN                                  FIX
──────────────────────────                  ──────────────────────────
pkill -SIGUSR2 ghostty                      pkill -x -SIGUSR2 ghostty
                                            
ghostty-helper / ghostty-shell 等を巻き込む  完全一致

該当: apply.sh:64
```

### A3. pkg-update の `tee "$cache_file"` が atomic でない

```
ANTIPATTERN                                  FIX
──────────────────────────                  ──────────────────────────
printf '...' | tee "$cache_file"             printf '...' >"$cache.tmp"
                                            mv "$cache.tmp" "$cache"
書き込み中に reader が走ると半端 JSON         cat "$cache"

L5 で cache 自体廃止するなら自然消滅           
そうでなければ tmp+mv で atomic 化
```

### M1. `state_get` の `grep | tail | cut` を bash builtin に

```
ANTIPATTERN                                  FIX
──────────────────────────                  ──────────────────────────
v=$(grep -E "^${key}=" $f                    while IFS='=' read -r k v; do
   | tail -1 | cut -d= -f2-)                   [[ "$k" == "$key" ]] && val=$v
                                              done <"$f"
3 fork / 呼び出し                             
                                            0 fork

L2 の SIGUSR1 化と組み合わせて poll fork 全廃
```

### M2. set 系 (`-euo pipefail`) 設定の不整合

```
現状の散らばり:
  wallpaper/*.sh           : -euo pipefail
  hyprctl-state, rotate.sh : -uo pipefail (e なし、意図的)
  weather.sh               : -e のみ
  rofi/*.sh, pkg-update/*  : 一切なし

修正方針:
  pkg-update に最低 set -u
  weather.sh に -uo pipefail
  rofi 対話 script は set -e と相性悪いので現状維持

set 設定を script 種別ごとに方針として固定する。
```

### M3. weather.sh で `awk '{print $N}' <<<` を4回 fork

```
ANTIPATTERN                                  FIX
──────────────────────────                  ──────────────────────────
T9=$(awk '{print $1}' <<<"$TEMPS")          IFS=$'\t' read -r T9 T0 LO HI <<<"$TEMPS"
T0=$(awk '{print $2}' <<<"$TEMPS")
LO=$(awk '{print $3}' <<<"$TEMPS")
HI=$(awk '{print $4}' <<<"$TEMPS")
                                            1 builtin
4 awk fork
```

### M4. `mktemp` テンプレートの `XXXX` が短い

```
ANTIPATTERN                                  FIX
──────────────────────────                  ──────────────────────────
mktemp "${STATE_FILE}.XXXX"                  mktemp "${STATE_FILE}.XXXXXX"
(16^4 = 65k)                                (16^6 = 16M, デフォルト)

該当: hyprctl-state:35
```

### M5. `[[ ]]` と `[ ]` の混在

```
pkg-update/*, thumb.sh は [ ] (POSIX 風)
他は [[ ]]

bash shebang なので [[ ]] に統一
```

### M6. state.env の concurrent set に flock なし

```
state_set は tmp+mv でファイル単位 atomic だが、
複数 set が同時に走ると tmp ファイル単位での last-writer-wins。

実害優先度は低 (rotate 30s + rofi interactive で衝突確率小)
だが、設計としては flock 推奨。

修正:
  exec 9>"$STATE_FILE.lock"
  flock 9
  ... 既存処理 ...
```

---

## 採否マトリクス

| ID | 内容 | 影響範囲 | 推奨 | 備考 |
|---|---|---|---|---|
| **L1-A** | rotation を queue モデルへ | pick.sh, init.sh, state スキーマ | ★★ | "全枚回す"派 |
| **L1-B** | shuffle cache 廃止、毎回 shuf -n 1 | pick.sh, init.sh | ★★ | "毎回ランダム"派、A と排他 |
| **L2** | rotate.sh SIGUSR1 化 | rotate.sh, rofi-wallpaper-settings | ★★ | M1と相乗 |
| L3 | pick.sh reroll 実装 | pick.sh | ★ | 画像枚数次第 |
| L4 | hyprctl reload boot 非同期 | apply.sh, init.sh | ★ | boot体感 |
| **L5** | pkg-update cache 全廃→ディスパッチャ | 6本+waybar config | ★★ | 重複ごと消える |
| L6 | mode.sh polling→event socket | mode.sh | △ | 実装重い |
| **L7** | RANDOM_ON_STARTUP を state 化 | init.sh, hyprctl-state | ★★ | 抽象漏れ修復 |
| **S1** | apply.sh 関数分割 | apply.sh | ★ | L4と相乗 |
| S2 | (L5 に内包) | — | — | — |
| **A1** | local var=$(cmd) 分離 | weather/init/apply 数十箇所 | ★★ | 失敗検知復活 |
| **A2** | pkill -x | apply.sh 1行 | ★★ | バグ防止 |
| **A3** | tee → tmp+mv | pkg-update 3本 | ★ | L5 で消える |
| **M1** | state_get bash builtin | hyprctl-state | ★★ | L2と相乗 |
| M2 | set 整合 | rofi/pkg-update/weather | ★ | |
| **M3** | weather.sh awk → read | weather.sh | ★ | |
| M4 | mktemp X4 → X6 | hyprctl-state | △ | LOW実質 |
| M5 | [[ ]] 統一 | pkg-update / thumb | △ | スタイル |
| M6 | state.env flock | hyprctl-state | △ | 実害低 |

★★ = 強推奨、★ = 推奨、△ = 余裕あれば

---

## 推奨実行順 (依存関係込み)

```
[Phase 1: 単独で完結する高 ROI 改造]
   L1 (A or B 選択), L2, L7, M1, A1, A2, M3
   ↓
[Phase 2: 構造再編]
   L5 (cache 廃止 + ディスパッチャ統合), S1 (apply.sh 分割), L4
   ↓
[Phase 3: 余裕があれば]
   L3, L6, M2, M4, M5, M6, A3 (L5 に内包される)
```

---

## 採否を決めて

最低限決めてほしい3つ:

1. **L1 は A (queue) か B (cache 廃止) か?** ← 動作モデルに直結
2. **L6 (event socket) はやる/やらない?** ← 実装重いので見送りも合理的
3. **Phase 1 全部進めて良い?** それとも個別?
